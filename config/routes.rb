Rails.application.routes.draw do
  # Dev : 127.0.0.1 -> localhost (même IP que le serveur Vite)
  constraints(host: "127.0.0.1") do
    get "(*path)", to: redirect { |params, req| "#{req.protocol}localhost:#{req.port}/#{params[:path]}" }
  end

  # Authentification
  get    "login",    to: "sessions#new",      as: :login
  post   "login",    to: "sessions#create"
  delete "logout",   to: "sessions#destroy",  as: :logout
  get    "register", to: "registrations#new", as: :register
  post   "register", to: "registrations#create"

  # Connexion Google (OmniAuth)
  get "auth/google_oauth2/callback", to: "users/omniauth#google"
  get "auth/failure",                to: "users/omniauth#failure"

  # Strava : connexion OAuth + webhooks temps réel
  get  "strava/connect",  to: "strava#connect",  as: :strava_connect
  get  "strava/callback", to: "strava#callback"
  get  "strava/webhook",  to: "strava/webhooks#verify"
  post "strava/webhook",  to: "strava/webhooks#event"

  get "up" => "rails/health#show", as: :rails_health_check

  root "hub#index"
end
