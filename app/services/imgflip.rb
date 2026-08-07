# Source de memes SANS AUCUNE CLÉ : l'API publique d'Imgflip renvoie les ~100 modèles
# populaires. Avec memegen.link, c'est le repli quand aucune clé Giphy n'est configurée,
# pour que la recherche marche dès la première installation.
#
# Le catalogue est stable : on le garde en cache une journée et `Memes` filtre par nom en
# mémoire — la recherche ne tape donc pas l'API à chaque lettre.
class Imgflip
  ENDPOINT = "https://api.imgflip.com/get_memes".freeze
  HOSTS = %w[i.imgflip.com].freeze

  def self.catalogue
    Rails.cache.fetch("imgflip/memes", expires_in: 1.day) { fetch } || []
  end

  def self.fetch
    json = Memes::Http.get_json(ENDPOINT, source: "imgflip")
    Array(json.dig("data", "memes")).filter_map do |m|
      next unless Memes.allowed?(m["url"])

      { id: "imgflip-#{m['id']}", url: m["url"], preview: m["url"], title: m["name"].to_s }
    end
  end
end
