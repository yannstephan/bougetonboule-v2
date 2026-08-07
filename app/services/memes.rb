# Façade des sources de memes du chat. Une seule porte d'entrée pour le contrôleur, le
# modèle et le catalogue — personne d'autre n'a à savoir d'où vient une image.
#
# Deux régimes :
#   1. `GIPHY_API_KEY` configurée → **Giphy**, vraie recherche sur un catalogue immense.
#      C'est le seul moyen d'avoir beaucoup de choix, et des GIF de réaction plutôt que
#      des modèles vierges.
#   2. Sinon → repli **sans aucune clé**, en cumulant Imgflip (~100) et memegen.link (~214).
#      Ça marche dès l'installation, mais ça reste un petit catalogue de modèles.
#
# `allowed?` est le garde-fou qui empêche `messages.meme_url` de devenir un champ
# « affiche l'image de ton choix » : seuls les hôtes des sources connues passent, et il est
# appliqué DEUX fois (contrôleur + modèle).
module Memes
  KEYLESS = [ Imgflip, Memegen ].freeze
  HOSTS = (Giphy::HOSTS + Imgflip::HOSTS + Memegen::HOSTS).freeze
  LIMIT = 36
  BROWSE_LIMIT = 60 # ce qu'on montre quand on feuillette sans chercher

  def self.giphy? = Giphy.configured?
  def self.source_name = giphy? ? "giphy" : "libre"

  # Champ vide = on PARCOURT. Sur un catalogue de quelques centaines d'entrées aux titres
  # anglais, chercher « bébé » ou « patron » ne donne rien : feuilleter est le bon geste.
  # Avec Giphy, le même geste montre les tendances du moment.
  def self.search(query)
    q = query.to_s.strip
    return browse if q.blank?
    return Giphy.search(q) if giphy?

    keyless_search(q)
  end

  def self.browse
    return Giphy.trending if giphy?

    KEYLESS.flat_map(&:catalogue).uniq { |m| m[:title].to_s.downcase }.first(BROWSE_LIMIT)
  end

  # Les deux catalogues libres, fusionnés et dédoublonnés par titre : les deux sources ont
  # une bonne part de modèles en commun (Drake, Distracted Boyfriend…).
  def self.keyless_search(q)
    needle = q.downcase
    KEYLESS.flat_map(&:catalogue)
           .select { |m| m[:title].to_s.downcase.include?(needle) }
           .uniq { |m| m[:title].to_s.downcase }
           .first(LIMIT)
  end

  def self.allowed?(url)
    uri = URI.parse(url.to_s)
    uri.scheme == "https" && uri.userinfo.nil? &&
      HOSTS.any? { |h| uri.host == h || uri.host.to_s.end_with?(".#{h}") }
  rescue URI::InvalidURIError
    false
  end
end
