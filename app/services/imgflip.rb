require "net/http"

# Source de memes SANS AUCUNE CLÉ : l'API publique d'Imgflip renvoie les ~100 modèles
# populaires. C'est le repli quand `GIPHY_API_KEY` n'est pas configurée, pour que la
# recherche marche dès la première installation plutôt que d'attendre une inscription.
#
# Le catalogue est stable : on le garde en cache une journée et on filtre par nom en
# mémoire — la recherche ne tape donc pas l'API à chaque lettre.
class Imgflip
  ENDPOINT = "https://api.imgflip.com/get_memes".freeze
  HOSTS = %w[i.imgflip.com].freeze
  TIMEOUT = 4

  # Le catalogue complet, mis en cache : il ne bouge quasiment jamais.
  def self.catalogue
    Rails.cache.fetch("imgflip/memes", expires_in: 1.day) { fetch } || []
  end

  def self.fetch
    uri = URI(ENDPOINT)
    res = Net::HTTP.start(uri.host, uri.port, use_ssl: true,
                          open_timeout: TIMEOUT, read_timeout: TIMEOUT) { |h| h.get(uri.request_uri) }
    return [] unless res.is_a?(Net::HTTPSuccess)

    json = JSON.parse(res.body)
    Array(json.dig("data", "memes")).filter_map do |m|
      next unless Memes.allowed?(m["url"])

      { id: "imgflip-#{m['id']}", url: m["url"], preview: m["url"], title: m["name"].to_s }
    end
  rescue StandardError => e
    Rails.logger.warn("[imgflip] #{e.class}: #{e.message}")
    []
  end
end
