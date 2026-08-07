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
    [ "https://media.giphy.com/media/abc/giphy.gif", "https://i.imgflip.com/30b1gx.jpg" ].each do |url|
      msg = @conv.messages.new(membership: @membership, meme_url: url, meme_title: "bravo")
      assert msg.save, "#{url} : #{msg.errors.full_messages.to_sentence}"
      end
  end

  test "une image de n'importe où est refusée" do
    %w[
      https://exemple.test/photo.jpg
      http://media.giphy.com/media/abc/giphy.gif
      https://media.giphy.com.attaquant.test/x.gif
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

  test "l'aperçu d'un meme sans texte parle quand même" do
    msg = @conv.messages.create!(membership: @membership, meme_title: "bien joué",
                                 meme_url: "https://i.imgflip.com/x.jpg")
    assert_equal "🖼️ bien joué", msg.preview
  end

  # Sans clé, la recherche doit quand même marcher : c'est tout l'intérêt du repli.
  test "sans clé Giphy, ce sont les catalogues libres qui répondent" do
    assert_not Giphy.configured?, "le décor de test ne doit pas porter de clé"
    assert_not Memes.giphy?, "sans clé, on doit être sur les catalogues libres"
    assert_equal [], Giphy.search("bravo"), "Giphy sans clé ne part pas en requête"
    with_catalogues { assert_equal [ "Drake Hotline Bling" ], Memes.search("drake").map { |m| m[:title] } }
  end

  # Champ vide = on feuillette. Sur un petit catalogue aux titres anglais, chercher
  # « bébé » ne donnerait rien : pouvoir parcourir est ce qui rend le sélecteur utilisable.
  test "un champ vide fait feuilleter le catalogue au lieu de ne rien rendre" do
    with_catalogues do
      assert_equal CATALOGUE.map { |m| m[:title] }.sort, Memes.search("").map { |m| m[:title] }.sort
      assert_equal Memes.search(""), Memes.search(nil)
    end
  end

  test "les deux catalogues sont fusionnés et dédoublonnés par titre" do
    doublon = [ CATALOGUE.first.merge(id: "memegen-doublon") ]
    with_catalogues([ CATALOGUE.first ], doublon) do
      assert_equal 1, Memes.browse.size, "le même titre ne doit apparaître qu'une fois"
    end
  end
end
