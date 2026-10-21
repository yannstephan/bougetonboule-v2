class ApplicationController < ActionController::Base
  include Authentication
  allow_browser versions: :modern

  # Avant tout le reste : inutile de monter une session pour un hôte qu'on va quitter.
  prepend_before_action :redirect_to_canonical_host

  helper_method :current_membership

  inertia_share do
    {
      auth: {
        user: current_user && {
          id: current_user.id, firstname: current_user.firstname, email: current_user.email,
          diamonds: current_user.diamonds, strava_connected: current_user.strava_connected?,
          unread_count: current_user.notifications.listed.unread.count,
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
      # Hud/BottomNav masquent les destinations de jeu tant que l'admin n'a pas affecté
      # le joueur à une équipe — seuls Strava et la FAQ restent accessibles.
      has_team: current_membership.present?,
      flash: { notice: flash.notice, alert: flash.alert, chest: flash[:chest] }
    }
  end

  # L'aura d'un joueur, telle que le fond de page la consomme. `nil` = pas d'aura, pas de fond.
  def aura_json(user)
    piece = user&.user_cosmetics&.includes(:cosmetic)&.find { |uc| uc.equipped && uc.cosmetic.slot == "aura" }
    # `rarity` : seules les auras épiques et légendaires s'animent en fond (AuraBackground).
    piece && { emoji: piece.cosmetic.emoji, art: piece.cosmetic.art, rarity: piece.cosmetic.rarity }
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

  # Garde partagée par tout ce qui suppose une équipe : tant que l'admin n'a pas affecté le
  # joueur (voir /admin), seuls Strava et la FAQ restent accessibles (cf. Hub en mode onboarding).
  def require_membership
    return if current_membership

    redirect_to root_path, alert: "Rejoins une équipe pour accéder à ça — en attendant, connecte Strava et jette un œil à la FAQ."
  end
  # Renvoie vers l'hôte canonique (config.x.canonical_host, posé en production). Voir
  # production.rb pour le pourquoi : Strava n'accepte qu'un seul domaine de rappel.
  #
  # ⚠️ Deux chemins ne doivent JAMAIS être redirigés :
  #   - `/strava/webhook` — l'abonnement pointe sur l'apex et Strava NE SUIT PAS les
  #     redirections : une 301 ferait échouer la validation et perdre des courses. Le
  #     contrôleur concerné saute donc ce filtre explicitement.
  #   - `/up` — il n'est pas concerné du tout, `rails/health#show` n'hérite pas d'ici.
  #
  # Seules les requêtes GET/HEAD sont redirigées : une 301 sur un POST serait transformée en
  # GET par les navigateurs, donc le corps du formulaire serait perdu.
  def redirect_to_canonical_host
    host = Rails.application.config.x.canonical_host
    return if host.blank? || request.host == host
    return unless request.get? || request.head?

    redirect_to "#{request.protocol}#{host}#{request.fullpath}",
                status: :moved_permanently, allow_other_host: true
  end
end
