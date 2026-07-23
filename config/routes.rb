Rails.application.routes.draw do
  constraints(host: "127.0.0.1") do
    get "(*path)", to: redirect { |params, req| "#{req.protocol}localhost:#{req.port}/#{params[:path]}" }
  end

  # Auth
  get    "login",    to: "sessions#new",      as: :login
  post   "login",    to: "sessions#create"
  delete "logout",   to: "sessions#destroy",  as: :logout
  get    "register", to: "registrations#new", as: :register
  post   "register", to: "registrations#create"
  get "auth/google_oauth2/callback", to: "users/omniauth#google"
  get "auth/failure",                to: "users/omniauth#failure"

  # Strava
  get  "strava/connect",  to: "strava#connect",  as: :strava_connect
  get  "strava/callback", to: "strava#callback"
  get  "strava/webhook",  to: "strava/webhooks#verify"
  post "strava/webhook",  to: "strava/webhooks#event"

  # Jeu
  get  "combat", to: "combat#show", as: :combat
  post "actions", to: "actions#create", as: :actions

  get  "chat", to: "chat#show", as: :chat
  post "conversations/:conversation_id/messages", to: "messages#create", as: :conversation_messages

  get   "notifications", to: "notifications#index", as: :notifications
  post  "notifications/read_all", to: "notifications#read_all", as: :read_all_notifications
  post  "push_subscriptions", to: "push_subscriptions#create", as: :push_subscriptions

  # PWA
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  get "up" => "rails/health#show", as: :rails_health_check
  root "hub#index"
end
