require "net/http"
require "json"

# Client de l'API Strava : échange de code, refresh de token, récupération d'activités.
class StravaClient
  API_BASE  = "https://www.strava.com/api/v3".freeze
  OAUTH_URL = "https://www.strava.com/oauth/token".freeze

  def self.client_id     = creds(:client_id, "STRAVA_CLIENT_ID")
  def self.client_secret = creds(:client_secret, "STRAVA_CLIENT_SECRET")

  def self.creds(key, env)
    Rails.application.credentials.dig(:strava, key) || ENV[env]
  end

  # Échange le code d'autorisation OAuth contre des tokens.
  def self.exchange_code(code)
    post_form(grant_type: "authorization_code", code:)
  end

  # Renvoie un access_token valide pour l'user (refresh si expiré), ou nil.
  def self.valid_token_for(user)
    return user.strava_token if user.strava_expires_at.nil? || user.strava_expires_at.future?

    data = post_form(grant_type: "refresh_token", refresh_token: user.strava_refresh_token)
    return nil unless data

    user.update!(
      strava_token:         data["access_token"],
      strava_refresh_token: data["refresh_token"],
      strava_expires_at:    Time.zone.at(data["expires_at"].to_i)
    )
    data["access_token"]
  end

  def self.post_form(**params)
    res = Net::HTTP.post_form(URI(OAUTH_URL),
      params.merge(client_id:, client_secret:).transform_keys(&:to_s))
    res.is_a?(Net::HTTPSuccess) ? JSON.parse(res.body) : nil
  rescue StandardError => e
    Rails.logger.error("[Strava OAuth] #{e.class}: #{e.message}")
    nil
  end

  def initialize(access_token)
    @access_token = access_token
  end

  def activity(id) = get("#{API_BASE}/activities/#{id}")

  def recent_runs(after: 7.days.ago)
    (get("#{API_BASE}/athlete/activities?after=#{after.to_i}&per_page=50") || [])
      .select { |a| a["type"] == "Run" }
  end

  private

  def get(url)
    return nil if @access_token.blank?

    uri = URI(url)
    req = Net::HTTP::Get.new(uri)
    req["Authorization"] = "Bearer #{@access_token}"
    res = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(req) }
    res.is_a?(Net::HTTPSuccess) ? JSON.parse(res.body) : nil
  rescue StandardError => e
    Rails.logger.error("[StravaClient] #{e.class}: #{e.message}")
    nil
  end
end
