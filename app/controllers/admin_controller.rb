# Back-office minimal, réservé à l'admin de la partie en cours (`Membership#admin?`).
#
# Couvre les réglages qui se pilotent sans déployer :
#   - les journées spéciales (×2 sur les boules) ;
#   - la fenêtre de disponibilité des cosmétiques (la boutique de saison) ;
#   - l'affectation des joueurs à une équipe (un `Membership` se crée toujours à la main —
#     il n'y a pas d'auto-inscription, voir la roadmap).
# Créer la partie elle-même (Event/Game/Teams) reste au seed — voir la roadmap.
class AdminController < ApplicationController
  before_action :require_authentication
  before_action :require_admin

  def show
    render inertia: "Admin", props: {
      game: { id: @game.id, name: @game.name,
              starts_at: @game.starts_at&.iso8601, ends_at: @game.ends_at&.iso8601 },
      today: Date.current.iso8601,
      special_days: special_days_json,
      cosmetics: cosmetics_json,
      teams: teams_json,
      players: players_json,
      unassigned_users: unassigned_users_json
    }
  end

  # Affecte un joueur pas encore dans la partie à une équipe : c'est le seul chemin pour
  # rejoindre une partie (pas d'auto-inscription, voir CLAUDE.md).
  def create_membership
    team = @game.teams.find_by(id: params[:team_id])
    user = User.find_by(id: params[:user_id])
    return redirect_to admin_path, alert: "Équipe ou joueur introuvable." unless team && user

    membership = Membership.new(user:, game: @game, team:, role: "player")
    if membership.save
      redirect_to admin_path, notice: "#{user.firstname.presence || user.email} rejoint #{team.name}."
    else
      redirect_to admin_path, alert: membership.errors.full_messages.to_sentence
    end
  end

  # Change l'équipe d'un joueur déjà affecté. Le fruit choisi appartient à l'ancienne
  # famille : on le remet à zéro plutôt que de planter la sauvegarde, le joueur re-choisira
  # sur l'écran Avatar.
  def update_membership
    membership = @game.memberships.find_by(id: params[:id])
    team = @game.teams.find_by(id: params[:team_id])
    return redirect_to admin_path, alert: "Joueur ou équipe introuvable." unless membership && team
    return redirect_to admin_path, notice: "Déjà dans cette équipe." if membership.team_id == team.id

    if membership.update(team:, fruit: nil)
      redirect_to admin_path, notice: "#{membership.display_name} déplacé·e vers #{team.name}."
    else
      redirect_to admin_path, alert: membership.errors.full_messages.to_sentence
    end
  end

  def create_special_day
    day = @game.special_days.new(special_day_params)
    if day.save
      redirect_to admin_path, notice: "Journée spéciale « #{day.name} » ajoutée."
    else
      redirect_to admin_path, alert: day.errors.full_messages.to_sentence
    end
  end

  def destroy_special_day
    day = @game.special_days.find(params[:id])
    day.destroy
    redirect_to admin_path, notice: "« #{day.name} » supprimée."
  end

  # Pose (ou retire) la fenêtre de disponibilité d'un cosmétique. Un champ vide = pas de
  # borne de ce côté ; les deux vides = la pièce redevient permanente.
  def update_cosmetic
    cosmetic = Cosmetic.find(params[:id])
    from  = parse_day(params[:available_from])
    until_ = parse_day(params[:available_until], end_of_day: true)

    if from && until_ && from > until_
      return redirect_to admin_path, alert: "La date de fin doit venir après la date de début."
    end

    cosmetic.update!(available_from: from, available_until: until_)
    redirect_to admin_path, notice: "#{cosmetic.name} : #{window_label(cosmetic)}"
  end

  private

  def require_admin
    @membership = current_membership
    return redirect_to root_path, alert: "Réservé à l'organisateur de la partie." unless @membership&.admin?

    @game = @membership.game
  end

  def special_day_params = params.permit(:name, :date, :multiplier)

  # Les dates arrivent en "YYYY-MM-DD" (input type=date) : on les lit dans le fuseau du jeu,
  # et une date de FIN vaut jusqu'au bout de sa journée (sinon elle expire à minuit pile).
  def parse_day(value, end_of_day: false)
    return nil if value.blank?

    day = Date.parse(value)
    end_of_day ? day.end_of_day : day.beginning_of_day
  rescue Date::Error
    nil
  end

  def window_label(cosmetic)
    return "disponible en permanence" unless cosmetic.seasonal?

    from = cosmetic.available_from&.to_date&.strftime("%d/%m/%Y")
    till = cosmetic.available_until&.to_date&.strftime("%d/%m/%Y")
    return "disponible jusqu'au #{till}" if from.nil?
    return "disponible à partir du #{from}" if till.nil?

    "disponible du #{from} au #{till}"
  end

  def special_days_json
    @game.special_days.order(:date).map do |d|
      { id: d.id, name: d.name, date: d.date.iso8601, multiplier: d.multiplier.to_f,
        past: d.date < Date.current }
    end
  end

  def cosmetics_json
    Cosmetic.order(:slot, :name).map do |c|
      { id: c.id, name: c.name, slot: c.slot, emoji: c.emoji, art: c.art,
        price: c.price_diamonds, rarity: c.rarity,
        available_from: c.available_from&.to_date&.iso8601,
        available_until: c.available_until&.to_date&.iso8601,
        live: c.available? }
    end
  end

  def teams_json
    @game.teams.order(:name).map { |t| { id: t.id, name: t.name, family: t.fruit_family } }
  end

  def players_json
    @game.memberships.includes(:user, :team).sort_by(&:display_name).map do |m|
      { id: m.id, name: m.display_name, email: m.user.email, team_id: m.team_id,
        role: m.role, admin: m.admin? }
    end
  end

  # Qui pourrait rejoindre cette partie : tout utilisateur qui n'y a pas encore de Membership
  # (il peut très bien en avoir un dans une autre partie, passée ou future).
  def unassigned_users_json
    assigned_ids = @game.memberships.select(:user_id)
    User.where.not(id: assigned_ids).order(:firstname).map do |u|
      { id: u.id, name: u.firstname.presence || u.email, email: u.email }
    end
  end
end
