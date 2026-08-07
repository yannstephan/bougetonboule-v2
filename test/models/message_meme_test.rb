require "test_helper"
require "support/game_setup"

# Un message peut porter un meme, et RIEN d'autre côté image : pas d'envoi de fichier, pas
# d'URL libre. Ce test verrouille la frontière — sans elle, `meme_url` serait un champ
# « affiche l'image de ton choix », posté à la main hors de l'app.
class MessageMemeTest < ActiveSupport::TestCase
  include GameSetup

  # Catalogues préchargés en cache : un test ne doit pas dépendre du réseau, et sans ça la
  # première recherche irait vraiment interroger Imgflip et memegen.
  CATALOGUE = [
    { id: "imgflip-1", url: "https://i.imgflip.com/30b1gx.jpg",
      preview: "https://i.imgflip.com/30b1gx.jpg", title: "Drake Hotline Bling" },
    { id: "memegen-3hd", url: "https://api.memegen.link/images/3hd.jpg",
      preview: "https://api.memegen.link/images/3hd.jpg?width=220", title: "Three-Headed Dragon" }
  ].freeze

  setup do
    setup_game
    @conv = Conversation.create!(game: @game, kind: "general")
    # ⚠️ En test, Rails.cache est un null_store : `fetch` rappellerait le bloc, donc les
    # catalogues partiraient VRAIMENT chercher Imgflip et memegen sur le réseau. Un vrai
    # cache mémoire le temps du test permet de les préremplir — et exerce le bon chemin.
    @real_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
  end

  teardown { Rails.cache = @real_cache }

  def with_catalogues(imgflip = [ CATALOGUE.first ], memegen = [ CATALOGUE.last ])
    Rails.cache.write("imgflip/memes", imgflip)
    Rails.cache.write("memegen/templates", memegen)
    yield
  end

  test "un meme du catalogue passe, quelle que soit la source" do
    # ⚠️ media0…media4 : Giphy tire l'hôte au hasard d'un appel à l'autre. Les lister tous
    # est le seul moyen d'attraper la régression qui refusait chaque GIF en silence.
    [ "https://media.giphy.com/media/abc/giphy.gif",
      "https://media0.giphy.com/media/abc/giphy.gif",
      "https://media4.giphy.com/media/abc/giphy-downsized.gif?cid=x",
      "https://i.giphy.com/media/abc/giphy.gif",
      "https://i.imgflip.com/30b1gx.jpg" ].each do |url|
      msg = @conv.messages.new(membership: @membership, meme_url: url, meme_title: "bravo")
      assert msg.save, "#{url} : #{msg.errors.full_messages.to_sentence}"
      end
  end

  test "une image de n'importe où est refusée" do
    %w[
      https://exemple.test/photo.jpg
      http://media.giphy.com/media/abc/giphy.gif
      https://media.giphy.com.attaquant.test/x.gif
      https://giphy.com.attaquant.test/x.gif
      https://notgiphy.com/x.gif
      https://i.imgflip.com.attaquant.test/x.jpg
      https://user:pass@media.giphy.com/x.gif
    ].each do |url|
      msg = @conv.messages.new(membership: @membership, meme_url: url)
      assert_not msg.valid?, "#{url} n'aurait pas dû passer"
      assert msg.errors[:meme_url].any?
    end
  end

  test "un message vide reste refusé" do
    assert_not @conv.messages.new(membership: @membership).valid?
  end

  test "un texte seul reste valide, un meme seul aussi" do
    assert @conv.messages.new(membership: @membership, body: "salut").valid?
    assert @conv.messages.new(membership: @membership,
                              meme_url: "https://i.imgflip.com/x.jpg").valid?
  end

  test "l'aperçu d'un GIF sans texte parle quand même" do
    msg = @conv.messages.create!(membership: @membership, meme_title: "bien joué",
                                 meme_url: "https://i.imgflip.com/x.jpg")
    assert_equal "🖼️ bien joué", msg.preview
  end

  # ⚠️ AUCUN test de ce fichier ne doit toucher le réseau. Dès qu'un `.env` porte une clé
  # Giphy, les tests du repli partaient interroger la vraie API : lents, dépendants d'un
  # service tiers, et rouges pour une raison sans rapport avec ce qu'ils vérifient.
  # On pose donc la clé (ou on la retire) autour de chaque test, et on remet tout en place.
  # Pas de `stub` : minitest 6 a sorti `minitest/mock` de la gem, et on n'ajoute pas une
  # dépendance pour trois tests.
  def keyless
    saved = Giphy::ENV_KEYS.to_h { |k| [ k, ENV.delete(k) ] }
    yield
  ensure
    saved.each { |k, v| ENV[k] = v if v }
  end

  # Sans clé, la recherche doit quand même marcher : c'est tout l'intérêt du repli.
  test "sans clé Giphy, ce sont les catalogues libres qui répondent" do
    keyless do
      assert_not Memes.giphy?, "sans clé, on doit être sur les catalogues libres"
      assert_equal [], Giphy.search("bravo"), "Giphy sans clé ne part pas en requête"
      with_catalogues { assert_equal [ "Drake Hotline Bling" ], Memes.search("drake").map { |m| m[:title] } }
    end
  end

  # Champ vide = on feuillette. Sur un petit catalogue aux titres anglais, chercher
  # « bébé » ne donnerait rien : pouvoir parcourir est ce qui rend le sélecteur utilisable.
  test "un champ vide fait feuilleter le catalogue au lieu de ne rien rendre" do
    keyless do
      with_catalogues do
        assert_equal CATALOGUE.map { |m| m[:title] }.sort, Memes.search("").map { |m| m[:title] }.sort
        assert_equal Memes.search(""), Memes.search(nil)
      end
    end
  end

  test "les deux catalogues sont fusionnés et dédoublonnés par titre" do
    doublon = [ CATALOGUE.first.merge(id: "memegen-doublon") ]
    keyless do
      with_catalogues([ CATALOGUE.first ], doublon) do
        assert_equal 1, Memes.browse.size, "le même titre ne doit apparaître qu'une fois"
      end
    end
  end

  # ————— Giphy —————
  # La réponse de l'API est simulée : le test vérifie ce qu'on FAIT de la réponse, pas que
  # Giphy réponde. Aucun appel réseau, quelle que soit la clé posée dans le .env.
  GIPHY_JSON = {
    "data" => [
      { "id" => "abc", "title" => "Dance Cat GIF",
        "images" => { "downsized" => { "url" => "https://media3.giphy.com/media/abc/giphy.gif" },
                      "fixed_width_small" => { "url" => "https://media3.giphy.com/media/abc/200w_s.gif" } } },
      # Sans `downsized`, on retombe sur `original`.
      { "id" => "def", "title" => nil,
        "images" => { "original" => { "url" => "https://media0.giphy.com/media/def/giphy.gif" } } },
      # Un hôte étranger doit être jeté, même servi par l'API.
      { "id" => "ghi", "title" => "Pirate",
        "images" => { "downsized" => { "url" => "https://cdn.attaquant.test/x.gif" } } }
    ]
  }.freeze

  # Clé factice + appel HTTP remplacé : on vérifie ce qu'on FAIT de la réponse, jamais que
  # Giphy réponde.
  def with_giphy(json = GIPHY_JSON)
    saved = Giphy::ENV_KEYS.to_h { |k| [ k, ENV[k] ] }
    ENV["GIPHY_KEY"] = "cle-de-test"
    Memes::Http.singleton_class.alias_method(:get_json_reseau, :get_json)
    Memes::Http.define_singleton_method(:get_json) { |*, **| json }
    yield
  ensure
    Memes::Http.singleton_class.alias_method(:get_json, :get_json_reseau)
    Memes::Http.singleton_class.remove_method(:get_json_reseau)
    Giphy::ENV_KEYS.each { |k| saved[k] ? ENV[k] = saved[k] : ENV.delete(k) }
  end

  test "avec une clé, la recherche passe par Giphy" do
    with_giphy do
      assert Memes.giphy?
      titres = Memes.search("chat").map { |m| m[:title] }
      assert_equal [ "Dance Cat GIF", "meme" ], titres, "le titre vide retombe sur un libellé"
    end
  end

  test "un GIF servi depuis un hôte étranger est jeté, même par l'API" do
    with_giphy do
      assert_equal %w[abc def], Memes.search("chat").map { |m| m[:id] }
    end
  end

  # La régression qui rendait la recherche vide même avec une clé valide : les images de
  # Giphy viennent de media0…media4, jamais de « media.giphy.com ».
  test "les GIF de media0…media4 passent la liste blanche" do
    with_giphy do
      urls = Memes.search("chat").map { |m| m[:url] }
      assert_equal 2, urls.size, "aucun GIF ne doit être jeté pour son sous-domaine"
      assert urls.all? { |u| Memes.allowed?(u) }
    end
  end

  test "champ vide avec une clé : ce sont les tendances" do
    with_giphy { assert_equal 2, Memes.browse.size }
  end
end
