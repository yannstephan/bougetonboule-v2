require "test_helper"
require "support/game_setup"

# Fumée : les écrans touchés par le contrôle des courses se rendent bien (props sérialisables).
class ScreensTest < ActionDispatch::IntegrationTest
  include GameSetup

  setup do
    setup_game
    @verified = ImportTraining.call(@membership, strava_activity)
    @rejected = ImportTraining.call(@membership, strava_activity(sport_type: "Ride"))
    post "/login", params: { email: @membership.user.email, password: "odyssea2027" }
  end

  test "le Hub affiche le quota du jour" do
    get "/"
    assert_response :success
    assert_match(/"day_quota":\{"used":8,"cap":10\}/, response.body)
  end

  test "le profil liste les sorties, y compris celles qui ne comptent pas" do
    get "/joueurs/#{@membership.id}"
    assert_response :success
  end

  test "la page d'une sortie refusée s'ouvre, avec le motif" do
    get "/courses/#{@rejected.id}"
    assert_response :success
    assert_match "Ce n'est pas une course à pied", response.body
  end

  test "la page d'une sortie comptée s'ouvre" do
    get "/courses/#{@verified.id}"
    assert_response :success
  end

  test "un compte Strava déjà pris par un autre joueur est refusé" do
    @foe.user.update!(strava_uid: "999")
    assert_not @membership.user.update(strava_uid: "999")
  end

  test "la FAQ s'ouvre" do
    get "/faq"
    assert_response :success
  end

  # Le décor importe une vraie course : DropChest peut y avoir fait tomber un coffre au
  # hasard. On repart d'un sac vide pour que le compte soit celui du test.
  test "le sac s'ouvre et liste les coffres scellés" do
    @membership.chests.destroy_all
    chest = @membership.chests.create!(rarity: "rare", reward_diamonds: 30)
    get "/sac"
    assert_response :success
    assert_match(/"chests":\[\{"id":#{chest.id},"rarity":"rare"\}\]/, response.body)
  end

  test "la pastille du sac compte les coffres à ouvrir" do
    @membership.chests.destroy_all
    get "/sac"
    assert_match(/"inventory_alert":0/, response.body)

    @membership.chests.create!(rarity: "common", reward_diamonds: 15)
    get "/sac"
    assert_match(/"inventory_alert":1/, response.body)
  end

  test "on ouvre un coffre depuis le sac" do
    chest = @membership.chests.create!(rarity: "common", reward_diamonds: 15)
    post "/coffres/#{chest.id}/ouvrir"
    assert_redirected_to "/sac"
    assert_equal "opened", chest.reload.status
  end

  test "les vieux liens vers le sac de la boutique y sont renvoyés" do
    get "/boutique?tab=inventory"
    assert_redirected_to "/sac"
  end

  test "l'armoire s'ouvre depuis le sac avec les pièces possédées" do
    cosmetic = Cosmetic.create!(name: "Chapeau test", slot: "hat", rarity: "common", emoji: "🎩")
    @membership.user.user_cosmetics.create!(cosmetic:, acquired_at: Time.current)

    get "/sac?tab=wardrobe"
    assert_response :success
    assert_match(/"initial_tab":"wardrobe"/, response.body)
    assert_match "Chapeau test", response.body
  end

  test "on équipe et on retire un cosmétique depuis le sac" do
    cosmetic = Cosmetic.create!(name: "Chapeau test", slot: "hat", rarity: "common", emoji: "🎩")
    owned = @membership.user.user_cosmetics.create!(cosmetic:, acquired_at: Time.current)

    post "/sac/equiper", params: { cosmetic_id: cosmetic.id, equipped: true }
    assert_redirected_to "/sac?tab=wardrobe"
    assert owned.reload.equipped

    post "/sac/equiper", params: { cosmetic_id: cosmetic.id, equipped: false }
    assert_not owned.reload.equipped
  end

  test "un seul cosmétique équipé par emplacement" do
    slot = %w[hat hat].each_with_index.map do |s, i|
      c = Cosmetic.create!(name: "Chapeau #{i}", slot: s, rarity: "common", emoji: "🎩")
      @membership.user.user_cosmetics.create!(cosmetic: c, acquired_at: Time.current)
    end

    post "/sac/equiper", params: { cosmetic_id: slot.first.cosmetic_id, equipped: true }
    post "/sac/equiper", params: { cosmetic_id: slot.second.cosmetic_id, equipped: true }

    assert_not slot.first.reload.equipped
    assert slot.second.reload.equipped
  end

  test "le fil du Hub liste les sorties des deux camps, sans les refusées" do
    ImportTraining.call(@foe, strava_activity)

    get "/"
    assert_response :success
    body = response.body
    mine = body[/"my_team":\{.*?"runs":(\[.*?\])/m, 1]
    foe  = body[/"opponent":\{.*?"runs":(\[.*?\])/m, 1]

    assert_match(/"who":"Coureur"/, mine)
    assert_match(/"who":"Adversaire"/, foe)
    # @rejected (un Ride) a été importé dans le décor : il ne doit apparaître nulle part.
    assert_no_match(/"id":#{@rejected.id}\b/, mine)
  end

  test "l'écran avatar garde le fruit, mais plus l'armoire" do
    get "/avatar"
    assert_response :success
    assert_match(/"component":"Avatar"/, response.body)
    assert_match(/"fruits":\[\{"key":"ananas"/, response.body)
    assert_no_match(/"cosmetics":\[/, response.body)
  end
end
