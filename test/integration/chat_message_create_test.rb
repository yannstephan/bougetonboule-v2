require "test_helper"
require "support/game_setup"

# Poster un message doit rouvrir le MÊME canal : la régression était un simple oubli du
# paramètre `canal` dans le redirect, qui ramenait toujours sur la conversation de la partie.
class ChatMessageCreateTest < ActionDispatch::IntegrationTest
  include GameSetup

  setup do
    setup_game
    @general = @game.conversations.create!(kind: "general")
    @team = @game.conversations.create!(kind: "team", team: @exo)
    post "/login", params: { email: @membership.user.email, password: "odyssea2027" }
  end

  test "écrire dans le canal d'équipe redirige vers le canal d'équipe" do
    post "/conversations/#{@team.id}/messages", params: { body: "coucou l'équipe" }

    assert_redirected_to "/chat?canal=team"
  end

  test "écrire dans le canal de la partie redirige vers le canal de la partie" do
    post "/conversations/#{@general.id}/messages", params: { body: "coucou tout le monde" }

    assert_redirected_to "/chat?canal=general"
  end
end
