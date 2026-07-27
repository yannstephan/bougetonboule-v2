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
  def has_route? = route_points.present?
  def has_photo? = photo_url.present?

  # Allure moyenne en secondes / km (nil si on n'a pas le temps de mouvement).
  def pace_seconds
    return nil if moving_time.to_i.zero? || distance_km.zero?

    (moving_time / distance_km).round
  end
end
