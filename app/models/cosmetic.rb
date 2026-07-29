class Cosmetic < ApplicationRecord
  RARITIES = %w[common rare epic legendary].freeze
  SLOTS    = %w[base hat eyes outfit arms legs aura].freeze
  SOURCES  = %w[shop drop event rank].freeze

  has_many :user_cosmetics, dependent: :destroy
  has_many :owners, through: :user_cosmetics, source: :user

  validates :name, :slot, :rarity, presence: true
  validates :slot, inclusion: { in: SLOTS }
  validates :rarity, inclusion: { in: RARITIES }
  validates :source, inclusion: { in: SOURCES }

  # En vente à la boutique : les récompenses (prix nul) ne s'achètent pas.
  scope :purchasable, -> { where.not(price_diamonds: nil) }
  # Tout ce qu'un joueur ne possède pas encore — la pioche des cadeaux (coffre, streak, ligue).
  scope :unowned_by, ->(user) { where.not(id: user.user_cosmetics.select(:cosmetic_id)) }
end
