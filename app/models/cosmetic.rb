class Cosmetic < ApplicationRecord
  RARITIES = %w[common rare epic legendary].freeze
  SLOTS    = %w[base hat eyes outfit aura].freeze
  SOURCES  = %w[shop drop event rank].freeze

  has_many :user_cosmetics, dependent: :destroy
  has_many :owners, through: :user_cosmetics, source: :user

  validates :name, :slot, :rarity, presence: true
  validates :slot, inclusion: { in: SLOTS }
  validates :rarity, inclusion: { in: RARITIES }

  scope :purchasable, -> { where.not(price_diamonds: nil) }
  scope :by_slot, ->(slot) { where(slot:) }
end
