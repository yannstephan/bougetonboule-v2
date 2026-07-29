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
end
