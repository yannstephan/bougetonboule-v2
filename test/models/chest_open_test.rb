require "test_helper"
require "support/game_setup"

# L'ouverture d'un coffre. Elle est idempotente (verrou + statut) et rend des gains
# STRUCTURÉS : la modal fait sortir du coffre la pièce elle-même (son dessin ou son emoji)
# et les 💎 en gros, elle a donc besoin de la matière, pas d'une phrase toute faite.
# C'est ce contrat-là que ce test verrouille — le front en dépend.
class ChestOpenTest < ActiveSupport::TestCase
  include GameSetup

  setup { setup_game }

  def cosmetic(**attrs)
    Cosmetic.create!({ name: "Chapeau d'or", slot: "hat", rarity: "legendary",
                       price_diamonds: 1000, source: "shop", emoji: "🎩" }.merge(attrs))
  end

  def chest(**attrs)
    Chest.create!({ membership: @membership, rarity: "common", status: "sealed",
                    reward_diamonds: 15 }.merge(attrs))
  end

  test "un coffre de 💎 seules rend un gain diamonds" do
    gains = chest(reward_diamonds: 60).open!

    assert_equal [ { kind: "diamonds", amount: 60 } ], gains
    assert_equal 60, @membership.user.reload.diamonds
  end

  test "le cosmétique sort avec sa matière et SA rareté, pas celle du coffre" do
    piece = cosmetic(art: "gold_hat")
    gains = chest(rarity: "common", reward_diamonds: 15, cosmetic: piece).open!

    loot = gains.last
    assert_equal "cosmetic", loot[:kind]
    assert_equal "Chapeau d'or", loot[:name]
    assert_equal "🎩", loot[:emoji]
    assert_equal "gold_hat", loot[:art]
    # Un coffre commun peut cracher un légendaire (DropChest tire dans tout le catalogue) :
    # c'est la rareté de la PIÈCE qui doit remonter.
    assert_equal "legendary", loot[:rarity]
    assert @membership.user.user_cosmetics.exists?(cosmetic: piece)
  end

  test "un doublon devient des 💎 de compensation, avec sa raison" do
    piece = cosmetic
    UserCosmetic.create!(user: @membership.user, cosmetic: piece, acquired_at: Time.current)

    gains = chest(cosmetic: piece).open!

    assert_equal [ "diamonds", "diamonds" ], gains.map { |g| g[:kind] }
    assert_equal GameRules::CHEST_DUPE_DIAMONDS, gains.last[:amount]
    assert_match(/Chapeau d'or/, gains.last[:note])
    assert_equal 1, @membership.user.user_cosmetics.count
  end

  # La couleur ET la durée de l'ouverture viennent de là : c'est le plus beau contenu qui
  # donne le ton, jamais le palier du coffre seul.
  test "un coffre commun qui cache un légendaire s'ouvre en légendaire" do
    assert_equal "legendary", chest(rarity: "common", cosmetic: cosmetic).loot_rarity
  end

  test "un coffre légendaire qui ne cache qu'un commun garde son or" do
    petit = cosmetic(name: "Casquette", rarity: "common")
    assert_equal "legendary", chest(rarity: "legendary", cosmetic: petit).loot_rarity
  end

  test "sans cosmétique, c'est le palier du coffre qui donne le ton" do
    assert_equal "epic", chest(rarity: "epic").loot_rarity
  end

  test "rouvrir un coffre ne rend rien et ne recrédite rien" do
    c = chest(reward_diamonds: 30)
    assert c.open!

    assert_nil c.open!
    assert_equal 30, @membership.user.reload.diamonds
    assert_equal 1, Reward.where(source: "chest", period: "chest-#{c.id}").count
  end

  # Les gains font un aller-retour par le flash (session sérialisée en JSON) avant
  # d'arriver au front : ils doivent survivre à ce trajet.
  test "les gains passent le sérialiseur JSON de la session sans se perdre" do
    piece = cosmetic
    gains = chest(cosmetic: piece).open!
    back = JSON.parse(gains.to_json)

    assert_equal "diamonds", back.first["kind"]
    assert_equal 15, back.first["amount"]
    assert_equal "Chapeau d'or", back.last["name"]
    assert_equal "legendary", back.last["rarity"]
  end
end
