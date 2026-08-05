class Cosmetic < ApplicationRecord
  RARITIES = %w[common rare epic legendary].freeze
  # L'avatar est une TÊTE de fruit : pas de tenue ni de jambes, donc pas de slot pour ça.
  # hat = chapeau · eyes = lunettes · neck = nœud pap'/cravate/écharpe/collier ·
  # hands = bras (gants, bras mécanique, baguette — un de chaque côté) ·
  # shoes = paire de chaussures sous le fruit · sidekick = accessoire posé à côté · aura = fond.
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

  # Le catalogue du moment : une pièce hors de sa fenêtre n'est ni en vente, ni tirable
  # (coffre, streak, ligue) — sinon un bonnet de Noël tomberait en juillet.
  scope :available, ->(at = Time.current) {
    where("available_from IS NULL OR available_from <= ?", at)
      .where("available_until IS NULL OR available_until >= ?", at)
  }
  # Les pièces à durée limitée, celles qui garnissent la « boutique de saison ».
  scope :seasonal, -> { where.not(available_from: nil).or(where.not(available_until: nil)) }

  def seasonal? = available_from.present? || available_until.present?

  def available?(at = Time.current)
    (available_from.nil? || available_from <= at) && (available_until.nil? || available_until >= at)
  end

  # Jours restants avant la fermeture (nil si la pièce ne ferme pas). 0 = dernier jour.
  def days_left(at = Time.current)
    return nil if available_until.nil?

    [ (available_until.to_date - at.to_date).to_i, 0 ].max
  end
end
