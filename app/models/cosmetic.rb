class Cosmetic < ApplicationRecord
  RARITIES = %w[common rare epic legendary].freeze
  # L'avatar est une TÊTE de fruit : pas de tenue ni de jambes, donc pas de slot pour ça.
  # hat = chapeau · eyes = lunettes · neck = nœud pap'/cravate/écharpe/collier ·
  # hands = bras (gants, bras mécanique, baguette — un de chaque côté) ·
  # shoes = paire de chaussures sous le fruit · sidekick = accessoire posé à côté · aura = fond.
  # L'ordre fixe celui des rayons de la boutique et de l'écran avatar.
  SLOTS    = %w[hat eyes neck hands shoes sidekick aura].freeze
  SOURCES  = %w[shop drop event rank].freeze

  belongs_to :cosmetic_set, optional: true
  has_many :user_cosmetics, dependent: :destroy
  has_many :owners, through: :user_cosmetics, source: :user

  validates :name, :slot, :rarity, presence: true
  validates :slot, inclusion: { in: SLOTS }
  validates :rarity, inclusion: { in: RARITIES }
  validate :rarity_matches_set

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

  # ————— Prix —————
  # `price_diamonds` est le prix CATALOGUE, celui qui ne bouge pas. Le prix réellement
  # payé est `current_price` : il tombe quand la panoplie de la pièce est en promo.
  # ⚠️ C'est la SEULE autorité sur le prix. Le front l'affiche, `Purchase` le débite —
  # personne ne recalcule une remise dans son coin, et poster un id à la main paie
  # exactement ce que la boutique annonce.
  # Arrondi au multiple de 5 le plus proche : une boutique n'affiche pas 72 💎, et un
  # arrondi qui tombe juste vaut mieux qu'un pourcentage exact que personne ne vérifie.
  def current_price(at = Time.current)
    return nil if price_diamonds.nil?

    rate = cosmetic_set&.promo_rate(at).to_i
    return price_diamonds if rate.zero?

    [ (price_diamonds * (100 - rate) / 500.0).round * 5, 5 ].max
  end

  def on_promo?(at = Time.current) = current_price(at) != price_diamonds

  private

  # Une panoplie est d'UNE rareté : c'est ce qui rend son prix lisible d'un coup d'œil
  # et ce qui permet à une promo de s'appliquer uniformément.
  def rarity_matches_set
    other = cosmetic_set&.cosmetics&.where&.not(id: id)&.first
    return if other.nil? || other.rarity == rarity

    errors.add(:rarity, "doit être « #{other.rarity} », comme le reste de la panoplie #{cosmetic_set.name}")
  end
end
