require "net/http"

module Memes
  # Le GET JSON partagé par les trois sources de memes. Elles avaient chacune leur copie du
  # `Net::HTTP.start` + `rescue` : trois endroits où corriger un timeout, et trois occasions
  # d'oublier que **la panne d'une API tierce ne doit jamais casser le chat**.
  #
  # C'est ce dernier point qui justifie la mise en commun : le repli silencieux est une règle
  # du projet, pas un détail d'implémentation de chaque source.
  module Http
    TIMEOUT = 5

    # Renvoie le JSON parsé, ou `fallback` si quoi que ce soit se passe mal (statut non 2xx,
    # timeout, JSON invalide, DNS…). `source` sert seulement à tracer.
    def self.get_json(url, source:, fallback: {})
      uri = URI(url)
      res = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https",
                            open_timeout: TIMEOUT, read_timeout: TIMEOUT) { |h| h.get(uri.request_uri) }
      return fallback unless res.is_a?(Net::HTTPSuccess)

      JSON.parse(res.body)
    rescue StandardError => e
      Rails.logger.warn("[#{source}] #{e.class}: #{e.message}")
      fallback
    end
  end
end
