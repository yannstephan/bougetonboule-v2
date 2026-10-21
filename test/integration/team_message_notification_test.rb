require "test_helper"
require "support/game_setup"

# Un message d'équipe se lit dans le chat : sa notif est poussée vers le canal d'équipe mais
# n'apparaît jamais dans la liste, où la toucher ne menait nulle part.
class TeamMessageNotificationTest < ActionDispatch::IntegrationTest
  include GameSetup

  setup do
    setup_game
    @team = @game.conversations.create!(kind: "team", team: @exo)
    @mate = create_membership(@exo, "coequipier")
  end

  test "la notif d'un message d'équipe pointe vers le canal et n'est pas listée" do
    post "/login", params: { email: @membership.user.email, password: "odyssea2027" }
    post "/conversations/#{@team.id}/messages", params: { body: "on attaque ce soir" }

    notif = @mate.user.notifications.find_by!(category: "message")
    assert_equal "/chat?canal=team", notif.link
    assert_not_includes @mate.user.notifications.listed, notif
  end
end
