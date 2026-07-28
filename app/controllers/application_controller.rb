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
          unread_count: current_user.notifications.unread.count,
          avatar: AvatarPresenter.new(current_user, membership: current_membership).as_json
        }
      },
      vapid_public_key: Rails.application.config.x.vapid[:public_key],
      chat_unread: current_membership&.unread_messages_count || 0,
      flash: { notice: flash.notice, alert: flash.alert, chest: flash[:chest] }
    }
  end

  private

  # Un joueur peut voir les profils / sorties des autres joueurs de ses parties.
  def shares_game?(game_id)
    current_user&.memberships&.exists?(game_id:)
  end

  def current_membership
    return unless current_user
    @current_membership ||= current_user.memberships
      .joins(:game).where(games: { status: "active" })
      .includes(:game, team: :monster).first
  end
end
