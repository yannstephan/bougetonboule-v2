require "test_helper"

# Fait le tour de tous les écrans : chacun doit répondre 200 avec sa page Inertia, et
# renvoyer un visiteur non connecté vers la connexion.
class NavigationTest < ActionDispatch::IntegrationTest
  setup do
    @game = create_game
    @exo, @red = @game.teams.to_a
    @me = create_player(@game, @exo, firstname: "Yann")
    @foe = create_player(@game, @red, firstname: "Chloé")
    @training = create_training(@me, km: 8)
    sign_in_as(@me.user)
  end

  test "les écrans du jeu répondent" do
    {
      root_path => "Hub", combat_path => "Combat", chat_path => "Chat",
      league_path => "Ligue", shop_path => "Boutique", avatar_path => "Avatar",
      notifications_path => "Notifications", faq_path => "Faq",
      player_path(@me) => "Profile", training_path(@training) => "Training"
    }.each do |path, component|
      get path
      assert_response :success, "#{path} devrait répondre 200"
      assert_includes response.body, component, "#{path} devrait rendre la page #{component}"
    end
  end

  test "sans partie, le hub montre l'accueil et les écrans de jeu redirigent" do
    @me.destroy!
    get root_path
    assert_response :success

    [combat_path, chat_path, league_path].each do |path|
      get path
      assert_redirected_to root_path
    end
  end

  test "un visiteur non connecté est renvoyé vers la connexion" do
    delete logout_path
    [root_path, combat_path, chat_path, league_path, shop_path, avatar_path].each do |path|
      get path
      assert_redirected_to login_path, "#{path} devrait exiger une connexion"
    end
  end

  test "on ne voit pas le profil d'un joueur d'une autre partie" do
    other = create_game
    stranger = create_player(other, other.teams.first, firstname: "Inconnu")

    get player_path(stranger)
    assert_redirected_to root_path
  end

  test "ouvrir le chat remet la pastille de non-lus à zéro" do
    @game.conversations.general.first.messages.create!(membership: @foe, body: "Coucou")
    assert_equal 1, @me.reload.unread_messages_count

    get chat_path
    assert_response :success
    assert_equal 0, @me.reload.unread_messages_count
  end

  test "ouvrir les notifications les marque comme lues" do
    Notification.create!(user: @me.user, game: @game, category: "chest", title: "Coffre")
    assert_equal 1, @me.user.notifications.unread.count

    get notifications_path
    assert_response :success
    assert_equal 0, @me.user.notifications.unread.count
  end

  test "le manifest et le service worker de la PWA sont servis" do
    get pwa_manifest_path(format: :json)
    assert_response :success

    get pwa_service_worker_path
    assert_response :success
    assert_includes response.body, "push"
  end
end
