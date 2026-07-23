require "net/http"
require "json"

# Petit client de l'API Strava. Récupère les courses (type "Run") d'un athlète.
class StravaClient
  API_BASE = "https://www.strava.com/api/v3".freeze

  def initialize(access_token)
    @access_token = access_token
  end

  # Retourne les courses depuis `after` (Time). [] en cas d'erreur / pas de token.
  def recent_runs(after: 7.days.ago)
    return [] if @access_token.blank?

    uri = URI("#{API_BASE}/athlete/activities?after=#{after.to_i}&per_page=50")
    req = Net::HTTP::Get.new(uri)
    req["Authorization"] = "Bearer #{@access_token}"

    res = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(req) }
    return [] unless res.is_a?(Net::HTTPSuccess)

    JSON.parse(res.body).select { |a| a["type"] == "Run" }
  rescue StandardError => e
    Rails.logger.error("[StravaClient] #{e.class}: #{e.message}")
    []
  end
end
