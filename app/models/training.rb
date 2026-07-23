class Training < ApplicationRecord
  STATUSES = %w[pending verified rejected trapped protected].freeze

  belongs_to :membership
  belongs_to :special_day, optional: true
  has_one :chest, dependent: :nullify
  has_one :user, through: :membership

  delegate :game, :team, to: :membership

  validates :status, inclusion: { in: STATUSES }

  scope :verified, -> { where(status: "verified") }

  def distance_km = distance_meters.to_f / 1000
end
