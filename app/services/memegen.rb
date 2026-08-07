# Deuxième source SANS CLÉ : les ~214 modèles de memegen.link. Cumulés à ceux d'Imgflip, ça
# fait un catalogue trois fois plus fourni, toujours sans inscription.
#
# Ça reste des MODÈLES (images vierges) aux titres anglais, pas des GIF de réaction : pour un
# vrai catalogue et une recherche en français, il faut une clé Giphy — voir Memes.
class Memegen
  ENDPOINT = "https://api.memegen.link/templates".freeze
  HOSTS = %w[api.memegen.link].freeze
  # La grille fait 125 px de côté : charger le modèle en 1200 px pour ça, des dizaines de
  # fois, ne remplit jamais l'écran. memegen sait redimensionner (224 Ko -> 27 Ko).
  PREVIEW_WIDTH = 220

  def self.catalogue
    Rails.cache.fetch("memegen/templates", expires_in: 1.day) { fetch } || []
  end

  def self.fetch
    Array(Memes::Http.get_json(ENDPOINT, source: "memegen", fallback: [])).filter_map do |t|
      url = t["blank"]
      next unless Memes.allowed?(url)

      { id: "memegen-#{t['id']}", url:, preview: "#{url}?width=#{PREVIEW_WIDTH}",
        title: t["name"].to_s }
    end
  end
end
