require "net/http"

# Deuxième source SANS CLÉ : les ~214 modèles de memegen.link. Cumulés à ceux d'Imgflip, ça
# fait un catalogue trois fois plus fourni, toujours sans inscription.
#
# Ça reste des MODÈLES (images vierges), pas des GIF de réaction : pour un vrai catalogue,
# il faut une clé Giphy — voir Memes.
class Memegen
  ENDPOINT = "https://api.memegen.link/templates".freeze
  HOSTS = %w[api.memegen.link].freeze
  TIMEOUT = 5
  # La grille fait 125 px de côté : charger le modèle en 1200 px pour ça, 120 fois, ne
  # remplit jamais l'écran. memegen sait redimensionner (224 Ko -> 27 Ko).
  PREVIEW_WIDTH = 220

  def self.catalogue
    Rails.cache.fetch("memegen/templates", expires_in: 1.day) { fetch } || []
  end

  def self.fetch
    uri = URI(ENDPOINT)
    res = Net::HTTP.start(uri.host, uri.port, use_ssl: true,
                          open_timeout: TIMEOUT, read_timeout: TIMEOUT) { |h| h.get(uri.request_uri) }
    return [] unless res.is_a?(Net::HTTPSuccess)

    Array(JSON.parse(res.body)).filter_map do |t|
      url = t["blank"]
      next unless Memes.allowed?(url)

      { id: "memegen-#{t['id']}", url:, preview: "#{url}?width=#{PREVIEW_WIDTH}",
        title: t["name"].to_s }
    end
  rescue StandardError => e
    Rails.logger.warn("[memegen] #{e.class}: #{e.message}")
    []
  end
end
