require "test_helper"
require "support/game_setup"

# L'aura n'est plus une couronne autour de l'avatar : elle peint le FOND de la page.
# Deux règles à tenir, et c'est le serveur qui les tranche :
#   1. sur mes pages, c'est MON aura — elle est donc partagée comme le solde de 🍑 ;
#   2. sur le profil d'un joueur, c'est la SIENNE (`page_aura`, qui prime).
class AuraBackgroundTest < ActionDispatch::IntegrationTest
  include GameSetup

  setup do
    setup_game
    post "/login", params: { email: @membership.user.email, password: "odyssea2027" }
  end

  def wear_aura(user, emoji)
    piece = Cosmetic.create!(name: "Aura #{SecureRandom.hex(3)}", slot: "aura", rarity: "common",
                             price_diamonds: 120, source: "shop", emoji:)
    UserCosmetic.create!(user:, cosmetic: piece, equipped: true, acquired_at: Time.current)
    piece
  end

  test "sans aura équipée, rien n'est servi — pas de fond" do
    get "/"
    assert_response :success
    assert_match(/"aura":null/, response.body)
  end

  test "mon aura est partagée sur toutes les pages, pas servie écran par écran" do
    wear_aura(@membership.user, "🔥")

    [ "/", "/ligue", "/boutique", "/sac" ].each do |path|
      get path
      assert_response :success
      assert_match(/"aura":\{"emoji":"🔥","art":null\}/, response.body, "aura absente de #{path}")
    end
  end

  # Une pièce d'un AUTRE emplacement ne doit pas se retrouver en fond d'écran.
  test "seule la pièce du slot aura peint le fond" do
    chapeau = Cosmetic.create!(name: "Casquette test", slot: "hat", rarity: "common",
                               price_diamonds: 100, source: "shop", emoji: "🧢")
    UserCosmetic.create!(user: @membership.user, cosmetic: chapeau, equipped: true,
                         acquired_at: Time.current)

    get "/"
    assert_match(/"aura":null/, response.body)
  end

  # Une pièce possédée mais décrochée ne compte pas non plus.
  test "une aura rangée dans l'armoire ne peint rien" do
    piece = wear_aura(@membership.user, "❄️")
    @membership.user.user_cosmetics.find_by(cosmetic: piece).update!(equipped: false)

    get "/"
    assert_match(/"aura":null/, response.body)
  end

  test "sur le profil d'un joueur, c'est SON aura qui prime sur la mienne" do
    wear_aura(@membership.user, "🔥")
    wear_aura(@foe.user, "❄️")

    get "/joueurs/#{@foe.id}"
    assert_response :success
    assert_match(/"page_aura":\{"emoji":"❄️","art":null\}/, response.body)
  end

  # Un joueur sans aura doit servir `page_aura: null` et NON rien du tout : c'est ce nil
  # explicite qui dit au front « pas de fond ici » au lieu de retomber sur la mienne.
  test "le profil d'un joueur sans aura efface la mienne au lieu de la laisser" do
    wear_aura(@membership.user, "🔥")

    get "/joueurs/#{@foe.id}"
    assert_response :success
    assert_match(/"page_aura":null/, response.body)
  end
end
