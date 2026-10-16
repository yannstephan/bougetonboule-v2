require "test_helper"
require "support/game_setup"

# Les non-lus du chat, CANAL PAR CANAL. Toute la subtilité tient en une phrase : ouvrir un
# canal ne doit pas effacer la pastille de l'autre. Avant, ouvrir le chat marquait les deux
# conversations lues d'un coup — les onglets ne pouvaient donc rien dire.
class ChatUnreadTest < ActionDispatch::IntegrationTest
  include GameSetup

  setup do
    setup_game
    @me = @membership
    @mate = create_membership(@exo, "coequipier")
    @general = @game.conversations.create!(kind: "general")
    @team = @game.conversations.create!(kind: "team", team: @exo)
    post "/login", params: { email: @me.user.email, password: "odyssea2027" }
  end

  def write(conv, from: @mate, body: "coucou")
    conv.messages.create!(membership: from, body:)
  end

  def unread = @me.reload.unread_by_conversation

  test "un message d'un autre compte comme non lu, pas le mien" do
    write(@general)
    write(@general, from: @me)

    assert_equal 1, unread[@general.id]
  end

  test "ouvrir un canal ne marque QUE celui-là comme lu" do
    write(@general)
    write(@team)
    assert_equal [ 1, 1 ], [ unread[@general.id], unread[@team.id] ]

    get "/chat", params: { canal: "general" }
    assert_response :success
    assert_equal 0, unread[@general.id], "le canal ouvert doit retomber à zéro"
    assert_equal 1, unread[@team.id], "l'autre canal garde sa pastille"
  end

  test "sans paramètre, c'est la partie qui s'ouvre" do
    write(@general)
    write(@team)

    get "/chat"
    assert_equal 0, unread[@general.id]
    assert_equal 1, unread[@team.id]
  end

  test "le canal ouvert est servi à zéro, pas avec son compte d'avant" do
    write(@team)

    get "/chat", params: { canal: "team" }
    # Le compte part au front DANS la conversation : il doit refléter l'état d'APRÈS la
    # lecture, sinon on verrait une pastille sur l'onglet qu'on est en train de lire.
    assert_match(/"kind":"team","unread":0/, response.body)
    assert_match(/"active_kind":"team"/, response.body)
  end

  test "un canal non ouvert garde son compte dans les props" do
    3.times { write(@team) }

    get "/chat", params: { canal: "general" }
    assert_match(/"kind":"team","unread":3/, response.body)
  end

  # La pastille du 💬 dans le bandeau reste la somme des deux : elle dit « il y a du neuf »,
  # les onglets disent « où ».
  test "le total du bandeau ne tombe pas à zéro tant qu'un canal n'est pas lu" do
    write(@general)
    write(@team)

    get "/chat", params: { canal: "general" }
    assert_match(/"chat_unread":1/, response.body)
  end

  # ————— Où la vue s'ouvre —————
  # Le chat s'ouvre sur le premier message NON LU, pas au bas du fil : sinon la pastille
  # annonce 5 messages et il faut remonter à l'aveugle pour les retrouver.
  test "le premier non-lu est servi au front, et c'est bien le PREMIER" do
    get "/chat", params: { canal: "general" } # pose le repère de lecture
    write(@general, body: "1")
    second = write(@general, body: "2")

    get "/chat", params: { canal: "general" }
    assert_match(/"first_unread":#{Message.where(body: "1").first.id}\b/, response.body)
    refute_match(/"first_unread":#{second.id}\b/, response.body)
  end

  test "tout lu : rien à montrer, la vue reste au dernier message" do
    write(@general)
    get "/chat", params: { canal: "general" }

    get "/chat", params: { canal: "general" }
    assert_match(/"first_unread":null/, response.body)
  end

  # ⚠️ Un canal jamais ouvert aurait TOUT son historique en non-lu : s'ancrer sur le premier
  # message, c'est ouvrir le chat au début de la saison. Une première visite s'ouvre en bas.
  test "une première visite ne plante pas le joueur au début de l'historique" do
    3.times { write(@general) }

    get "/chat", params: { canal: "general" }
    assert_match(/"first_unread":null/, response.body)
  end

  test "mes propres messages ne font pas un repère" do
    get "/chat", params: { canal: "general" }
    write(@general, from: @me)

    get "/chat", params: { canal: "general" }
    assert_match(/"first_unread":null/, response.body)
  end

  # Le repère est celui du canal OUVERT : c'est le seul fil que le front rende.
  test "le repère suit le canal ouvert" do
    get "/chat", params: { canal: "team" }
    attendu = write(@team)
    write(@general)

    get "/chat", params: { canal: "team" }
    assert_match(/"first_unread":#{attendu.id}\b/, response.body)
  end

  test "un message d'une autre équipe ne se voit pas dans mon canal d'équipe" do
    autre = @game.conversations.create!(kind: "team", team: @red)
    write(autre, from: @foe)

    assert_nil unread[autre.id], "ce n'est pas une de mes conversations"
    assert_equal 0, @me.reload.unread_messages_count
  end
end
