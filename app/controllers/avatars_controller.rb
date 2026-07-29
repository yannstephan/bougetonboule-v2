class AvatarsController < ApplicationController
  before_action :require_authentication
  before_action :set_membership

  def show
    render inertia: "Avatar", props: {
      has_team: @membership.present?,
      strava_connected: current_user.strava_connected?,
      team: team_json,
      fruits: fruits_json,
      current_fruit: @membership&.fruit,
      avatar: AvatarPresenter.new(current_user, membership: @membership).as_json,
      cosmetics: owned_cosmetics,
      slots: Cosmetic::SLOTS
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

  # Équipe (ou retire) un cosmétique possédé. Un seul par slot.
  def equip
    owned = current_user.user_cosmetics.includes(:cosmetic).find_by(cosmetic_id: params[:cosmetic_id])
    return redirect_to avatar_path, alert: "Tu ne possèdes pas ce cosmétique." unless owned

    UserCosmetic.transaction do
      current_user.user_cosmetics.joins(:cosmetic)
                  .where(cosmetics: { slot: owned.cosmetic.slot }).update_all(equipped: false)
      owned.update!(equipped: params[:equipped].to_s != "false")
    end
    redirect_to avatar_path
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

  def owned_cosmetics
    current_user.user_cosmetics.includes(:cosmetic).map do |uc|
      { id: uc.cosmetic.id, name: uc.cosmetic.name, slot: uc.cosmetic.slot,
        rarity: uc.cosmetic.rarity, emoji: uc.cosmetic.emoji, art: uc.cosmetic.art,
        equipped: uc.equipped }
    end
  end
end
