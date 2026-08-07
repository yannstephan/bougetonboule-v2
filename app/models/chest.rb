class Chest < ApplicationRecord
  RARITIES = %w[common rare epic legendary].freeze
  STATUSES = %w[sealed opened].freeze

  belongs_to :membership
  belongs_to :training, optional: true
  belongs_to :cosmetic, optional: true

  validates :rarity, inclusion: { in: RARITIES }

  scope :sealed, -> { where(status: "sealed") }

  def sealed? = status == "sealed"

  # La rareté que le joueur VOIT à l'ouverture : celle du plus beau contenu, pas le palier
  # du coffre. Un coffre commun qui cache un légendaire s'ouvre EN OR — c'est le meilleur
  # moment que le jeu sache produire, il ne doit pas se jouer en gris. Et un coffre
  # légendaire qui ne cache qu'un chapeau commun garde l'or de son palier : on prend
  # toujours le PLUS HAUT des deux (RARITIES est un ordre), jamais le plus bas.
  # C'est elle, et pas `rarity`, qui part au front — il n'a jamais besoin du palier brut.
  def loot_rarity
    [ rarity, cosmetic&.rarity ].compact.max_by { |r| RARITIES.index(r) || -1 }
  end

  # Révèle le contenu (décidé au drop) : crédite les 💎 et le cosmétique, enregistre le
  # tout dans le registre rewards. Idempotent (verrou + statut) — retourne la liste des
  # gains, ou nil si le coffre était déjà ouvert.
  #
  # Des gains STRUCTURÉS, pas des phrases : la modal d'ouverture fait sortir du coffre la
  # pièce elle-même (son dessin ou son emoji) et les 💎 en gros. Elle a donc besoin de la
  # matière — un « 🎩 Chapeau » en texte ne se dessine pas.
  def open!
    with_lock do
      break nil unless sealed?

      update!(status: "opened", opened_at: Time.current)
      user = membership.user
      gains = []

      user.increment!(:diamonds, reward_diamonds)
      Reward.create!(user:, membership:, amount: reward_diamonds, reward_type: "diamonds",
                     source: "chest", period: "chest-#{id}")
      gains << { kind: "diamonds", amount: reward_diamonds }

      if cosmetic
        if user.user_cosmetics.exists?(cosmetic_id: cosmetic.id)
          # Acquis entre le drop et l'ouverture : compensation en 💎 plutôt qu'un doublon.
          user.increment!(:diamonds, GameRules::CHEST_DUPE_DIAMONDS)
          gains << { kind: "diamonds", amount: GameRules::CHEST_DUPE_DIAMONDS,
                     note: "tu avais déjà #{cosmetic.name}" }
        else
          UserCosmetic.create!(user:, cosmetic:, acquired_at: Time.current, source_game: membership.game)
          Reward.create!(user:, membership:, cosmetic:, reward_type: "cosmetic",
                         source: "chest", period: "chest-#{id}-cosmetic")
          # rarity : celle de la PIÈCE, pas celle du coffre — un coffre commun peut très
          # bien cracher un légendaire (DropChest tire dans tout le catalogue), et c'est
          # le meilleur moment que le jeu sait produire. Il doit se voir.
          gains << { kind: "cosmetic", name: cosmetic.name, emoji: cosmetic.emoji,
                     art: cosmetic.art, rarity: cosmetic.rarity }
        end
      end

      gains
    end
  end
end
