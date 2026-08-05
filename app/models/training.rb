class Training < ApplicationRecord
  STATUSES = %w[pending verified rejected trapped protected].freeze

  belongs_to :membership
  belongs_to :special_day, optional: true
  has_one :chest, dependent: :nullify
  has_one :user, through: :membership

  delegate :game, :team, to: :membership

  validates :status, inclusion: { in: STATUSES }

  scope :verified, -> { where(status: "verified") }
  # Courses qui rapportent : vérifiées, ou protégées d'un piège par une jambe de bois.
  scope :scoring, -> { where(status: %w[verified protected]) }
  scope :recent, -> { order(date: :desc) }

  def distance_km = distance_meters.to_f / 1000
  def rejected? = status == "rejected"

  # Verse les 🍑 de la course à la participation, dans la limite du porte-monnaie
  # (GameRules::WALLET_CAP) : l'excédent est perdu. Le score de la course reste entier —
  # c'est lui que compte la ligue. Idempotent (balls_credited_at) : la réconciliation
  # quotidienne peut repasser sans jamais payer deux fois.
  # Retourne le nombre de 🍑 réellement versées (nil si rien n'était à verser).
  def credit_balls!
    return if balls_credited_at.present? || !status.in?(%w[verified protected]) || score.to_i.zero?

    with_lock do
      break if balls_credited_at.present?

      credited = [ score.to_i, GameRules::WALLET_CAP - membership.reload.balls ].min.clamp(0, score.to_i)
      membership.increment!(:balls, credited) if credited.positive?
      update!(balls_credited_at: Time.current, credited_balls: credited)
      credited
    end
  end

  # Reprend les 🍑 versées par cette course (course supprimée sur Strava, ou requalifiée en
  # « ne compte pas » après modification). On ne reprend que ce qui a été réellement versé,
  # et le solde ne descend jamais sous zéro : les boules déjà dépensées sont perdues pour
  # tout le monde, on ne met personne en négatif. Retourne le nombre de 🍑 reprises.
  def uncredit_balls!
    return 0 if balls_credited_at.blank?

    with_lock do
      break 0 if balls_credited_at.blank?

      taken = [ credited_balls.to_i, membership.reload.balls ].min.clamp(0, credited_balls.to_i)
      membership.decrement!(:balls, taken) if taken.positive?
      update!(balls_credited_at: nil, credited_balls: 0)
      taken
    end
  end

  def has_route? = route_points.present?
  def has_photo? = photo_url.present?

  # Allure moyenne en secondes / km (nil si on n'a pas le temps de mouvement).
  def pace_seconds
    return nil if moving_time.to_i.zero? || distance_km.zero?

    (moving_time / distance_km).round
  end
end
