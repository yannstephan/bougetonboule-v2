class ApplicationController < ActionController::Base
  include Authentication
  allow_browser versions: :modern

  helper_method :current_membership

  inertia_share do
    {
      auth: {
        user: current_user && {
          id: current_user.id, firstname: current_user.firstname, email: current_user.email,
          diamonds: current_user.diamonds, strava_connected: current_user.strava_connected?,
          unread_count: current_user.notifications.unread.count
        }
      },
      vapid_public_key: Rails.application.config.x.vapid[:public_key],
      flash: { notice: flash.notice, alert: flash.alert }
    }
  end

  private

  def current_membership
    return unless current_user
    @current_membership ||= current_user.memberships
      .joins(:game).where(games: { status: "active" })
      .includes(:game, team: :monster).first
  end
end
