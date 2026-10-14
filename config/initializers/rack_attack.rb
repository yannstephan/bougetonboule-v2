# Limitation du débit des requêtes (voir le Gemfile pour le pourquoi).
#
# L'enjeu n'est PAS le vol de comptes — les mots de passe sont en bcrypt. C'est la
# DISPONIBILITÉ : bcrypt coûte volontairement ~100 ms de CPU par essai, donc quelques
# centaines de tentatives de connexion par minute suffisent à saturer l'unique vCPU et à
# rendre le jeu lent pour tout le monde. Un domaine public se fait scanner par des bots dans
# les jours qui suivent sa mise en ligne, sans malveillance particulière.
# Désactivé en test : des tests qui postent plusieurs fois sur /login déclencheraient la
# limite et deviendraient instables sans rapport avec ce qu'ils vérifient.
Rack::Attack.enabled = false if Rails.env.test?

class Rack::Attack
  # Une seule machine, un seul worker Puma (WEB_CONCURRENCY=1 dans fly.toml) : un compteur en
  # mémoire suffit. On évite exprès Solid Cache, qui est une base SQLite — on ne veut pas une
  # écriture disque à chaque requête juste pour compter.
  self.cache.store = ActiveSupport::Cache::MemoryStore.new(size: 8.megabytes)

  ### Ce qui ne doit JAMAIS être limité ###

  # ⚠️ Le webhook Strava arrive en rafale (tous les coureurs publient leur sortie le dimanche
  # matin) et une requête refusée = une course potentiellement perdue. Jamais de limite ici.
  safelist("strava webhook") { |req| req.path.start_with?("/strava/webhook") }

  # Le contrôle de santé de Fly frappe /up toutes les 15 s.
  safelist("health check") { |req| req.path == "/up" }

  ### La connexion : la vraie cible ###

  # Par IP : de quoi se tromper plusieurs fois de mot de passe sans jamais gêner un joueur.
  throttle("login/ip", limit: 10, period: 1.minute) do |req|
    req.ip if req.post? && req.path == "/login"
  end

  # Par email visé : empêche un attaquant réparti sur plusieurs IP de marteler UN compte.
  throttle("login/email", limit: 10, period: 20.minutes) do |req|
    req.params["email"].to_s.downcase.strip.presence if req.post? && req.path == "/login"
  end

  # Création de comptes : 20 joueurs attendus sur la saison, 5 par heure et par IP est large.
  throttle("register/ip", limit: 5, period: 1.hour) do |req|
    req.ip if req.post? && req.path == "/register"
  end

  # Garde-fou général contre le scan de bots. Volontairement haut : un joueur qui navigue
  # vite dans l'app ne doit jamais le toucher.
  throttle("req/ip", limit: 300, period: 5.minutes, &:ip)

  # Réponse lisible plutôt qu'une page d'erreur nue.
  self.throttled_responder = lambda do |_req|
    [ 429, { "content-type" => "text/plain; charset=utf-8" },
      [ "Trop de tentatives. Reprends ton souffle et réessaie dans une minute.\n" ] ]
  end
end
