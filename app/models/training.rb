class Training < ApplicationRecord
  STATUSES = %w[pending verified rejected trapped protected].freeze
  # Courses qui rapportent : vérifiées, ou protégées d'un piège par une jambe de bois.
  SCORING_STATUSES = %w[verified protected].freeze

  belongs_to :membership
  belongs_to :special_day, optional: true
  has_one :chest, dependent: :nullify

  validates :status, inclusion: { in: STATUSES }

  scope :scoring, -> { where(status: SCORING_STATUSES) }
  scope :recent, -> { order(date: :desc) }

  def distance_km = distance_meters.to_f / 1000
  def scoring? = status.in?(SCORING_STATUSES)
  def has_route? = route_points.present?
  def has_photo? = photo_url.present?

  # Verse les 🍑 de la course à la participation, dans la limite du porte-monnaie
  # (GameRules::WALLET_CAP) : l'excédent est perdu. Le score de la course reste entier —
  # c'est lui que compte la ligue. Idempotent (balls_credited_at) : la réconciliation
  # quotidienne peut repasser sans jamais payer deux fois.
  # Retourne le nombre de 🍑 réellement versées (nil si rien n'était à verser).
  def credit_balls!
    return if balls_credited_at.present? || !scoring? || score.to_i.zero?

    with_lock do
      break if balls_credited_at.present?

      credited = [score.to_i, GameRules::WALLET_CAP - membership.reload.balls].min.clamp(0, score.to_i)
      membership.increment!(:balls, credited) if credited.positive?
      update!(balls_credited_at: Time.current)
      credited
    end
  end

  # Allure moyenne en secondes / km (nil si on n'a pas le temps de mouvement).
  def pace_seconds
    return nil if moving_time.to_i.zero? || distance_km.zero?

    (moving_time / distance_km).round
  end
end
