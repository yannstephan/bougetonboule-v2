class AvatarsController < ApplicationController
  before_action :require_authentication
  before_action :set_membership

  # Le fruit-avatar et le compte. Les cosmétiques, eux, se gèrent dans le sac (/sac, onglet 🎨).
  def show
    render inertia: "Avatar", props: {
      has_team: @membership.present?,
      strava_connected: current_user.strava_connected?,
      is_admin: @membership&.admin? || false,
      team: team_json,
      fruits: fruits_json,
      current_fruit: @membership&.fruit,
      avatar: AvatarPresenter.new(current_user, membership: @membership).as_json
    }
  end

  # Choix du fruit-avatar. Réservé aux joueurs affectés à une équipe.
  def update
    return redirect_to avatar_path, alert: "Rejoins une équipe pour choisir ton fruit." unless @membership

    if @membership.update(fruit: params[:fruit])
      redirect_to avatar_path, notice: "Avatar mis à jour !"
    else
      redirect_to avatar_path, alert: @membership.errors.full_messages.to_sentence
    end
  end

  private

  def set_membership = @membership = current_membership

  def team_json
    return nil unless @membership

    team = @membership.team
    { name: team.name, family: team.fruit_family,
      family_label: FruitCatalog.family(team.fruit_family)&.dig(:label) }
  end

  # Chaque fruit de l'équipe, avec les coéquipiers qui l'ont déjà choisi (partage autorisé,
  # on l'indique juste). `mine` marque le fruit courant du joueur.
  def fruits_json
    return [] unless @membership

    chosen = teammates_by_fruit
    @membership.team.fruits.map do |fruit|
      { key: fruit[:key], name: fruit[:name],
        taken_by: chosen[fruit[:key]] || [],
        mine: @membership.fruit == fruit[:key] }
    end
  end

  # { "ananas" => ["Léa", "Max"] } — coéquipiers (hors moi) par fruit choisi.
  def teammates_by_fruit
    @membership.team.memberships.includes(:user).where.not(id: @membership.id)
               .each_with_object(Hash.new { |h, k| h[k] = [] }) do |m, acc|
      acc[m.fruit] << m.display_name if m.fruit.present?
    end
  end
end
