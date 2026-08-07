# Recherche de memes (GIF de réaction) chez Giphy, pour le chat.
#
# Secret OPTIONNEL, comme Strava/Google/VAPID : sans `GIPHY_API_KEY`, `configured?` est faux
# et `Memes` bascule sur les sources sans clé. Giphy reste le seul moyen d'avoir un vrai
# catalogue (des millions de GIF, et une recherche qui comprend le français via `lang`).
#
# Aucune gem ajoutée : Net::HTTP suffit pour un GET JSON. Et surtout aucun contenu n'est
# stocké — on ne garde que l'URL du GIF choisi, l'hébergement reste chez Giphy (c'est ce qui
# permet de ne pas revenir sur la décision « aucune pièce jointe » du Gemfile).
class Giphy
  SEARCH = "https://api.giphy.com/v1/gifs/search".freeze
  TRENDING = "https://api.giphy.com/v1/gifs/trending".freeze
  LIMIT = 24

  # Les hôtes d'où peuvent venir les GIF (voir Memes.allowed?).
  HOSTS = %w[media.giphy.com i.giphy.com].freeze

  # Deux noms acceptés : `GIPHY_KEY` (le plus court, celui du .env) et `GIPHY_API_KEY`
  # (la convention des autres secrets du projet). Sinon les credentials Rails chiffrés.
  ENV_KEYS = %w[GIPHY_KEY GIPHY_API_KEY].freeze

  def self.key
    ENV_KEYS.filter_map { |k| ENV[k].presence }.first ||
      Rails.application.credentials.dig(:giphy, :api_key)
  end
  def self.configured? = key.present?

  def self.search(query)
    q = query.to_s.strip
    return [] if q.blank? || !configured?

    call(SEARCH, q:)
  end

  # Ce qu'on montre quand le champ de recherche est vide : les tendances du moment.
  def self.trending
    return [] unless configured?

    call(TRENDING)
  end

  # Le repli silencieux en cas de panne vit dans Memes::Http, partagé par les trois sources.
  def self.call(endpoint, **extra)
    query = URI.encode_www_form(api_key: key, limit: LIMIT, rating: "pg-13",
                                lang: "fr", bundle: "messaging_non_clips", **extra)
    parse(Memes::Http.get_json("#{endpoint}?#{query}", source: "giphy"))
  end

  # On ne garde que ce qu'il faut pour afficher et envoyer : une vignette légère pour la
  # grille, le GIF pour le message, et le titre (qui sert aussi de texte alternatif).
  def self.parse(json)
    Array(json["data"]).filter_map do |gif|
      full = gif.dig("images", "downsized", "url") || gif.dig("images", "original", "url")
      preview = gif.dig("images", "fixed_width_small", "url") || full
      next unless Memes.allowed?(full)

      { id: gif["id"], url: full, preview:, title: gif["title"].presence || "meme" }
    end
  end

  private_class_method :call, :parse
end
