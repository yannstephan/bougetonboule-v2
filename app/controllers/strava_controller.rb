class StravaController < ApplicationController
  before_action :require_authentication

  def connect
    redirect_to authorize_url, allow_other_host: true
  end

  def callback
    token = StravaClient.exchange_code(params[:code])
    return redirect_to root_path, alert: "Connexion Strava échouée." unless token && token["access_token"]

    connected = current_user.update(
      strava_uid:           token.dig("athlete", "id")&.to_s,
      strava_token:         token["access_token"],
      strava_refresh_token: token["refresh_token"],
      strava_expires_at:    Time.zone.at(token["expires_at"].to_i)
    )

    if connected
      redirect_to root_path, notice: "Compte Strava connecté ! Tes courses s'importeront automatiquement."
    else
      # Un compte Strava = un joueur : il est déjà relié à un autre joueur de l'app.
      redirect_to root_path, alert: "Ce compte Strava est déjà utilisé par un autre joueur."
    end
  end

  # Délie le compte Strava : on efface le jeton et l'identifiant athlète (les courses ne
  # s'importeront plus jusqu'à une nouvelle connexion). Les courses déjà importées restent.
  def disconnect
    current_user.update!(strava_uid: nil, strava_token: nil,
                         strava_refresh_token: nil, strava_expires_at: nil)
    redirect_to avatar_path, notice: "Compte Strava déconnecté."
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
