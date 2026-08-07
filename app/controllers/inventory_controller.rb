# Le sac du joueur : tout ce qu'il possède, en deux onglets. « Objets » tient les coffres
# scellés (qu'on ouvre ici, plus sur le Hub), les objets à usage unique et ceux déjà posés,
# tous liés à la partie en cours. « Armoire » tient les cosmétiques, qui eux sont globaux —
# c'est le seul endroit d'où l'on équipe. Accessible par son onglet du footer, près de la boutique.
class InventoryController < ApplicationController
  before_action :require_authentication

  def show
    m = current_membership
    render inertia: "Inventaire", props: {
      has_team: m.present?,
      initial_tab: params[:tab] == "wardrobe" ? "wardrobe" : "items",
      balls: m&.balls || 0,
      chests: chests_json(m),
      inventory: inventory_json(m),
      armed: armed_effects_json(m),
      opponents: opponents_json(m),
      team_names: m && { mine: m.team.name, foe: m.team.opponent&.name,
                         mine_monster: m.team.monster&.name, foe_monster: m.team.opponent&.monster&.name },
      avatar: AvatarPresenter.new(current_user, membership: m).as_json,
      cosmetics: owned_cosmetics,
      slots: Cosmetic::SLOTS
    }
  end

  # Utiliser un objet du sac (à usage unique) — réutilise la logique de combat.
  def use_item
    m = current_membership
    return redirect_to inventory_path, alert: "Aucune partie active." unless m

    result = PerformAction.call(m, action_type: "use_item", item_id: params[:item_id],
                                   target_id: params[:target_id], target_team: params[:target_team])
    flash[result.ok ? :notice : :alert] = result.message
    redirect_to inventory_path
  end

  # Équipe (ou retire) un cosmétique possédé. Un seul par slot.
  def equip
    owned = current_user.user_cosmetics.includes(:cosmetic).find_by(cosmetic_id: params[:cosmetic_id])
    return redirect_to inventory_path(tab: "wardrobe"), alert: "Tu ne possèdes pas ce cosmétique." unless owned

    UserCosmetic.transaction do
      current_user.user_cosmetics.joins(:cosmetic)
                  .where(cosmetics: { slot: owned.cosmetic.slot }).update_all(equipped: false)
      owned.update!(equipped: params[:equipped].to_s != "false")
    end
    redirect_to inventory_path(tab: "wardrobe")
  end

  private

  # L'armoire : les pièces possédées, quelle que soit leur fenêtre de vente (ce qui est
  # acquis reste acquis, même hors saison).
  def owned_cosmetics
    current_user.user_cosmetics.includes(:cosmetic).map do |uc|
      { id: uc.cosmetic.id, name: uc.cosmetic.name, slot: uc.cosmetic.slot,
        rarity: uc.cosmetic.rarity, emoji: uc.cosmetic.emoji, art: uc.cosmetic.art,
        equipped: uc.equipped }
    end
  end

  # Les coffres pas encore ouverts, du plus ancien au plus récent.
  def chests_json(membership)
    return [] unless membership

    membership.chests.sealed.order(:created_at).map { |c| { id: c.id, rarity: c.rarity } }
  end

  # Objets possédés (non utilisés), regroupés par type avec leur nombre.
  def inventory_json(membership)
    return [] unless membership

    membership.membership_items.unused.includes(:item)
              .group_by(&:item_id).map do |_item_id, rows|
      item = rows.first.item
      { item_id: item.id, name: item.name, description: item.description,
        effect_type: item.effect_type, count: rows.size,
        active: membership.team.item_effect_active?(item.effect_type) }
    end
  end

  # Objets « à retardement » posés et pas encore résolus : jambe de bois armée (sur soi) et
  # pièges à loup en attente (avec la cible). Ils ont quitté le sac mais restent en jeu.
  def armed_effects_json(membership)
    return [] unless membership

    Action.joins(:item)
          .where(items: { effect_type: %w[wooden_leg trap] }, resolved_at: nil, membership: membership)
          .includes(:item)
          .recent
          .map do |a|
      { effect_type: a.item.effect_type,
        target: a.target.is_a?(Membership) ? a.target.display_name : nil,
        placed_at: a.created_at.strftime("%-d/%-m à %H:%M") }
    end
  end

  # Adversaires ciblables par un piège à loup.
  def opponents_json(membership)
    foe = membership&.team&.opponent
    return [] unless foe

    foe.memberships.includes(:user).map { |m| { id: m.id, name: m.display_name } }
  end
end
