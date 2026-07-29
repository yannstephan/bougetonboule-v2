namespace :strava do
  SUB_URL = "https://www.strava.com/api/v3/push_subscriptions".freeze

  desc "Crée l'abonnement webhook (CALLBACK_URL=https://ton-domaine/strava/webhook)"
  task subscribe: :environment do
    require "net/http"
    res = Net::HTTP.post_form(URI(SUB_URL),
      "client_id" => StravaClient.client_id, "client_secret" => StravaClient.client_secret,
      "callback_url" => ENV.fetch("CALLBACK_URL"), "verify_token" => StravaClient.verify_token)
    puts res.code, res.body
  end

  desc "Affiche l'abonnement webhook actuel"
  task view: :environment do
    require "net/http"
    uri = URI(SUB_URL)
    uri.query = URI.encode_www_form(client_id: StravaClient.client_id, client_secret: StravaClient.client_secret)
    puts Net::HTTP.get(uri)
  end

  desc "Supprime l'abonnement (SUB_ID=...)"
  task delete: :environment do
    require "net/http"
    uri = URI("#{SUB_URL}/#{ENV.fetch('SUB_ID')}")
    uri.query = URI.encode_www_form(client_id: StravaClient.client_id, client_secret: StravaClient.client_secret)
    req = Net::HTTP::Delete.new(uri)
    res = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |h| h.request(req) }
    puts res.code
  end
end
