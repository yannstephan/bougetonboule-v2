class ApplicationController < ActionController::Base
  include Authentication
  allow_browser versions: :modern

  inertia_share do
    {
      auth: {
        user: current_user && {
          id: current_user.id,
          firstname: current_user.firstname,
          email: current_user.email,
          diamonds: current_user.diamonds,
          strava_connected: current_user.strava_connected?
        }
      },
      flash: { notice: flash.notice, alert: flash.alert }
    }
  end
end
