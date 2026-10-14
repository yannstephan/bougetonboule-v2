require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module BougetonbouleV2
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # Tout le jeu se joue à l'heure française : le quota journalier de boules, les journées
    # spéciales et les échéances d'effets doivent tomber sur le bon jour pour les joueurs.
    config.time_zone = "Europe/Paris"

    # Le Gemfile acte que l'app ne stocke AUCUNE pièce jointe (les photos de sortie sont des
    # URL Strava), donc pas d'image_processing. Sans ce réglage, Active Storage avertit à
    # chaque démarrage qu'il manque la gem — un message inquiétant pour rien dans les logs.
    config.active_storage.variant_processor = :disabled

    # ——— Chiffrement des jetons Strava (voir User) ———
    # Les jetons Strava sont la donnée la plus sensible de la base : un jeton
    # d'actualisation permet de lire les activités d'un joueur jusqu'à révocation. Ils sont
    # donc chiffrés au repos (Active Record Encryption), pas seulement protégés par l'accès
    # au serveur.
    #
    # Les clés viennent de l'ENVIRONNEMENT et non des credentials chiffrés : le projet n'a
    # pas de master.key et tous ses secrets ont déjà un repli ENV (voir CLAUDE.md).
    # Générer une paire une fois pour toutes avec `bin/rails db:encryption:init`.
    #
    # ⚠️ Ces clés ne se changent JAMAIS après coup : sans elles, les jetons déjà en base
    # sont définitivement illisibles et tous les joueurs doivent reconnecter Strava.
    if Rails.env.local?
      # En local, des clés fixes et publiques : l'app doit tourner sans aucun secret, c'est
      # la convention du projet. Elles ne protègent rien et ne doivent jamais servir ailleurs.
      config.active_record.encryption.primary_key = "dev-cle-locale-sans-valeur-de-secret-01"
      config.active_record.encryption.deterministic_key = "dev-cle-locale-sans-valeur-de-secret-02"
      config.active_record.encryption.key_derivation_salt = "dev-sel-local-sans-valeur-de-secret-03"
    else
      # SECRET_KEY_BASE_DUMMY est posé par `assets:precompile` dans l'image Docker : à ce
      # moment-là il n'y a aucun secret et il ne FAUT pas échouer, sinon l'image ne se
      # construit plus.
      if ENV["AR_ENCRYPTION_PRIMARY_KEY"].blank? && ENV["SECRET_KEY_BASE_DUMMY"].blank?
        raise "Clés de chiffrement absentes. Génère-les avec `bin/rails db:encryption:init`, " \
              "puis pose AR_ENCRYPTION_PRIMARY_KEY, AR_ENCRYPTION_DETERMINISTIC_KEY et " \
              "AR_ENCRYPTION_KEY_DERIVATION_SALT (fly secrets set)."
      end
      config.active_record.encryption.primary_key = ENV["AR_ENCRYPTION_PRIMARY_KEY"]
      config.active_record.encryption.deterministic_key = ENV["AR_ENCRYPTION_DETERMINISTIC_KEY"]
      config.active_record.encryption.key_derivation_salt = ENV["AR_ENCRYPTION_KEY_DERIVATION_SALT"]
    end

    # Un jeton écrit en clair AVANT la bascule reste lisible : sinon la restauration d'une
    # vieille sauvegarde ferait perdre la connexion Strava de tout le monde d'un coup.
    config.active_record.encryption.support_unencrypted_data = true
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
