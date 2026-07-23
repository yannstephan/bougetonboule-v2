class StravaController < ApplicationController
  before_action :require_authentication

  def connect
    redirect_to authorize_url, allow_other_host: true
  end

  def callback
    token = StravaClient.exchange_code(params[:code])
    if token && token["access_token"]
      current_user.update!(
        strava_uid:           token.dig("athlete", "id")&.to_s,
        strava_token:         token["access_token"],
        strava_refresh_token: token["refresh_token"],
        strava_expires_at:    Time.zone.at(token["expires_at"].to_i)
      )
      redirect_to root_path, notice: "Compte Strava connecté ! Tes courses s'importeront automatiquement."
    else
      redirect_to root_path, alert: "Connexion Strava échouée."
    end
  end

  private

  def authorize_url
    query = {
      client_id:       StravaClient.client_id,
      redirect_uri:    "#{request.base_url}/strava/callback",
      response_type:   "code",
      approval_prompt: "auto",
      scope:           "read,activity:read_all"
    }.to_query
    "https://www.strava.com/oauth/authorize?#{query}"
  end
end
