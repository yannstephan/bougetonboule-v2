class Chest < ApplicationRecord
  RARITIES = %w[common rare epic legendary].freeze
  STATUSES = %w[sealed opened].freeze

  belongs_to :membership
  belongs_to :training, optional: true
  belongs_to :cosmetic, optional: true

  validates :rarity, inclusion: { in: RARITIES }

  scope :sealed, -> { where(status: "sealed") }

  def sealed? = status == "sealed"

  # Révèle le contenu (décidé au drop) : crédite les 💎 et le cosmétique, enregistre le
  # tout dans le registre rewards. Idempotent (verrou + statut) — retourne la liste des
  # gains en texte, ou nil si le coffre était déjà ouvert.
  def open!
    with_lock do
      break nil unless sealed?

      update!(status: "opened", opened_at: Time.current)
      user = membership.user
      gains = []

      user.increment!(:diamonds, reward_diamonds)
      Reward.create!(user:, membership:, amount: reward_diamonds, reward_type: "diamonds",
                     source: "chest", period: "chest-#{id}")
      gains << "+#{reward_diamonds} 💎"

      if cosmetic
        if user.user_cosmetics.exists?(cosmetic_id: cosmetic.id)
          # Acquis entre le drop et l'ouverture : compensation en 💎 plutôt qu'un doublon.
          user.increment!(:diamonds, GameRules::CHEST_DUPE_DIAMONDS)
          gains << "+#{GameRules::CHEST_DUPE_DIAMONDS} 💎 (tu avais déjà #{cosmetic.name})"
        else
          UserCosmetic.create!(user:, cosmetic:, acquired_at: Time.current, source_game: membership.game)
          Reward.create!(user:, membership:, cosmetic:, reward_type: "cosmetic",
                         source: "chest", period: "chest-#{id}-cosmetic")
          gains << "#{cosmetic.emoji} #{cosmetic.name}"
        end
      end

      gains
    end
  end
end
