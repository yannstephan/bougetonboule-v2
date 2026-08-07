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
      # Le HUD est sur toutes les pages : son solde de 🍑 doit donc être partagé, pas servi
      # écran par écran.
      balls: current_membership&.balls || 0,
      chat_unread: current_membership&.unread_messages_count || 0,
      # Pastille de l'onglet 🎒 : du nouveau dans le sac (aujourd'hui, un coffre scellé).
      inventory_alert: current_membership&.chests&.sealed&.count || 0,
      # L'aura équipée peint le FOND de toutes les pages (voir AuraBackground) : elle est
      # donc partagée comme le solde de 🍑, et non servie écran par écran. Une page peut la
      # remplacer en servant `page_aura` — c'est ce que fait le profil d'un joueur.
      aura: aura_json(current_user),
      flash: { notice: flash.notice, alert: flash.alert, chest: flash[:chest] }
    }
  end

  # L'aura d'un joueur, telle que le fond de page la consomme. `nil` = pas d'aura, pas de fond.
  def aura_json(user)
    piece = user&.user_cosmetics&.includes(:cosmetic)&.find { |uc| uc.equipped && uc.cosmetic.slot == "aura" }
    piece && { emoji: piece.cosmetic.emoji, art: piece.cosmetic.art }
  end
  helper_method :aura_json

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
