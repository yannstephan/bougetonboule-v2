class Cosmetic < ApplicationRecord
  RARITIES = %w[common rare epic legendary].freeze
  # L'avatar est une TÊTE de fruit : pas de tenue ni de jambes, donc pas de slot pour ça.
  # hat = chapeau · eyes = lunettes · neck = nœud pap'/cravate/écharpe/collier ·
  # hands = gants (un de chaque côté) · shoes = paire de chaussures sous le fruit ·
  # sidekick = accessoire posé à côté (animal, gourde, barre…) · aura = fond.
  # L'ordre fixe celui des rayons de la boutique et de l'écran avatar.
  SLOTS    = %w[hat eyes neck hands shoes sidekick aura].freeze
  SOURCES  = %w[shop drop event rank].freeze

  has_many :user_cosmetics, dependent: :destroy
  has_many :owners, through: :user_cosmetics, source: :user

  validates :name, :slot, :rarity, presence: true
  validates :slot, inclusion: { in: SLOTS }
  validates :rarity, inclusion: { in: RARITIES }

  scope :purchasable, -> { where.not(price_diamonds: nil) }
  scope :by_slot, ->(slot) { where(slot:) }
end
