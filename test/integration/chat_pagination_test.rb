require "test_helper"
require "support/game_setup"

# Le fil ne part jamais en entier. Une conversation de saison finit à plusieurs milliers de
# messages et l'écran se recharge toutes les 8 s : tout envoyer, c'est payer l'historique
# complet huit fois par minute. On sert la dernière page, et on remonte à la demande.
class ChatPaginationTest < ActionDispatch::IntegrationTest
  include GameSetup

  PAGE = ChatController::PAGE

  setup do
    setup_game
    @me = @membership
    @mate = create_membership(@exo, "coequipier")
    @general = @game.conversations.create!(kind: "general")
    @team = @game.conversations.create!(kind: "team", team: @exo)
    post "/login", params: { email: @me.user.email, password: "odyssea2027" }
  end

  # ⚠️ Toutes les visites se font en XHR Inertia : la réponse est alors le même objet de page,
  # mais en JSON — pas de HTML à désosser. Et il faut la VERSION des assets, sinon Inertia
  # répond 409 : il refuse de servir des props à un front qui pourrait tourner sur d'anciens
  # fichiers. C'est `ViteRuby.digest`, comme dans l'initialiseur.
  def visit(params = {}, only: nil)
    headers = { "X-Inertia" => "true", "X-Inertia-Version" => ViteRuby.digest }
    headers.merge!("X-Inertia-Partial-Component" => "Chat",
                   "X-Inertia-Partial-Data" => only) if only
    get("/chat", params:, headers:)
    assert_response :success
    JSON.parse(response.body)["props"]
  end

  # Des created_at explicites et croissants : c'est l'ordre que la pagination doit respecter.
  def fill(conv, count, from: @mate)
    (1..count).map do |i|
      conv.messages.create!(membership: from, body: "message #{i}",
                            created_at: 10.days.ago + i.minutes)
    end
  end

  test "on ne sert que la dernière page, et on dit qu'il en reste" do
    fill(@general, PAGE + 12)

    conv = visit["conversations"].find { _1["kind"] == "general" }

    assert_equal PAGE, conv["messages"].size
    assert conv["has_more"], "il reste 12 messages avant : le front doit pouvoir les demander"
    assert_equal "message 13", conv["messages"].first["body"], "la page est la plus RÉCENTE"
    assert_equal "message #{PAGE + 12}", conv["messages"].last["body"]
  end

  test "une conversation qui tient d'un coup n'annonce pas de suite" do
    fill(@general, 4)

    conv = visit["conversations"].find { _1["kind"] == "general" }
    assert_equal 4, conv["messages"].size
    refute conv["has_more"]
  end

  # ⚠️ La moitié du poids de la page, gagnée sans rien perdre : le front ne rend jamais le fil
  # de l'onglet fermé, et l'ouvrir est une visite qui le servira à ce moment-là.
  test "l'onglet fermé ne porte aucun message" do
    fill(@general, 5)
    fill(@team, 5)

    fermee = visit({ canal: "general" })["conversations"].find { _1["kind"] == "team" }

    assert_empty fermee["messages"]
    refute fermee["has_more"]
    assert_equal 5, fermee["unread"], "mais elle garde sa pastille, c'est tout son rôle"
  end

  test "remonter le fil sert la page d'avant, sans recouvrement" do
    all = fill(@general, PAGE + 12)
    pivot = all[12] # le plus ancien de la dernière page

    older = visit({ canal: "general", avant: pivot.id }, only: "older")["older"]

    assert_equal pivot.id, older["before"]
    assert_equal 12, older["messages"].size
    assert_equal "message 1", older["messages"].first["body"]
    assert_equal "message 12", older["messages"].last["body"], "strictement AVANT le pivot"
    refute older["has_more"], "on est remonté au premier message"
  end

  test "deux pages d'un coup laissent encore de l'historique" do
    all = fill(@general, PAGE * 3)
    older = visit({ canal: "general", avant: all[PAGE * 2].id }, only: "older")["older"]

    assert_equal PAGE, older["messages"].size
    assert older["has_more"]
  end

  # ⚠️ Le tri du serveur est (created_at, id) : le seed pose des dates à la main, deux messages
  # peuvent partager la seconde. Sans l'id en second critère, la frontière d'une page sauterait
  # ou répéterait un message.
  test "l'id départage deux messages de la même seconde" do
    t = 3.days.ago.change(usec: 0)
    a, b, c = 3.times.map { |i| @general.messages.create!(membership: @mate, body: "ex#{i}", created_at: t) }

    older = visit({ canal: "general", avant: c.id }, only: "older")["older"]
    assert_equal [ a.id, b.id ], older["messages"].map { _1["id"] }
  end

  test "un pivot qui n'existe pas ne rend rien plutôt que le début du fil" do
    fill(@general, 5)
    assert_nil visit({ canal: "general", avant: 999_999 }, only: "older")["older"]
  end

  # ⚠️ `memes` et `older` sont des props `optional` : elles ne sont PAS calculées au chargement
  # de la page ni au sondage de 8 s. C'est ce qui empêche `Memes.search` de partir chez Giphy
  # huit fois par minute et par onglet ouvert, pour un panneau que personne n'a ouvert.
  test "les props coûteuses ne sont pas dans la page" do
    keys = visit.keys
    refute_includes keys, "memes"
    refute_includes keys, "older"
  end

  test "le sondage du fil ne les calcule pas davantage" do
    fill(@general, 3)
    only = visit({ canal: "general" }, only: "conversations")

    # `errors` est une prop partagée d'inertia_rails, présente partout : ce qu'on vérifie ici,
    # c'est qu'AUCUNE des deux props coûteuses ne s'est glissée dans un sondage.
    assert_equal %w[conversations], only.keys - %w[errors]
  end
end
