class Chest < ApplicationRecord
  RARITIES = %w[common rare epic legendary].freeze
  STATUSES = %w[sealed opened].freeze

  belongs_to :membership
  belongs_to :training, optional: true
  belongs_to :cosmetic, optional: true

  validates :rarity, inclusion: { in: RARITIES }
  validates :status, inclusion: { in: STATUSES }

  scope :sealed, -> { where(status: "sealed") }

  def sealed? = status == "sealed"

  # Révèle le contenu (décidé au drop) : crédite les 💎 et le cosmétique, enregistre le
  # tout dans le registre rewards. Idempotent (verrou + statut) — retourne la liste des
  # gains en texte, ou nil si le coffre était déjà ouvert.
  def open!
    with_lock do
      break nil unless sealed?

      update!(status: "opened", opened_at: Time.current)
      gains = [GrantReward.label(give_diamonds(reward_diamonds, "chest-#{id}"))]
      gains << cosmetic_gain if cosmetic
      gains
    end
  end

  private

  def give_diamonds(amount, period)
    GrantReward.give_diamonds(membership, amount, source: "chest", period:)
  end

  # Le cosmétique du coffre — sauf s'il a été acquis entre le drop et l'ouverture :
  # dans ce cas c'est une compensation en 💎, pas un doublon.
  def cosmetic_gain
    if membership.user.user_cosmetics.exists?(cosmetic_id:)
      give_diamonds(GameRules::CHEST_DUPE_DIAMONDS, "chest-#{id}-dupe")
      "+#{GameRules::CHEST_DUPE_DIAMONDS} 💎 (tu avais déjà #{cosmetic.name})"
    else
      GrantReward.label(GrantReward.give_cosmetic(membership, cosmetic,
                                                  source: "chest", period: "chest-#{id}-cosmetic"))
    end
  end
end
