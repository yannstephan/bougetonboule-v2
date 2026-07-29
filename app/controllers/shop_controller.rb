class ShopController < ApplicationController
  before_action :require_authentication

  RARITY_ORDER = %w[common rare epic legendary].freeze

  def index
    m = current_membership
    render inertia: "Boutique", props: {
      has_team: m.present?,
      initial_tab: %w[items cosmetics inventory].include?(params[:tab]) ? params[:tab] : "items",
      balls: m&.balls || 0,
      items: items_json(m),
      cosmetics: cosmetics_json,
      inventory: inventory_json(m),
      armed: armed_effects_json(m),
      opponents: opponents_json(m),
      team_names: m && { mine: m.team.name, foe: m.team.opponent&.name,
                         mine_monster: m.team.monster&.name, foe_monster: m.team.opponent&.monster&.name }
    }
  end

  # Achat d'un objet en 🍑 (dépend de la participation).
  def buy_item
    item = Item.find(params[:item_id])
    result = Purchase.item(current_membership, item)
    flash[result.ok ? :notice : :alert] = result.message
    redirect_to shop_path
  end

  # Achat d'un cosmétique en 💎 (global).
  def buy_cosmetic
    cosmetic = Cosmetic.find(params[:cosmetic_id])
    result = Purchase.cosmetic(current_user, cosmetic, source_game: current_membership&.game)
    flash[result.ok ? :notice : :alert] = result.message
    redirect_to shop_path
  end

  # Utiliser un objet de l'inventaire (à usage unique) — réutilise la logique de combat.
  def use_item
    m = current_membership
    return redirect_to shop_path, alert: "Aucune partie active." unless m

    result = PerformAction.call(m, action_type: "use_item", item_id: params[:item_id],
                                   target_id: params[:target_id], target_team: params[:target_team])
    flash[result.ok ? :notice : :alert] = result.message
    redirect_to shop_path
  end

  private

  def items_json(membership)
    owned = membership ? membership.membership_items.unused.group(:item_id).count : {}
    Item.not_miscellaneous.order(:price).map do |item|
      { id: item.id, name: item.name, description: item.description,
        effect_type: item.effect_type, price: item.price, owned: owned[item.id] || 0 }
    end
  end

  def cosmetics_json
    owned = current_user.user_cosmetics.includes(:cosmetic).index_by(&:cosmetic_id)
    Cosmetic.purchasable
            .sort_by { |c| [RARITY_ORDER.index(c.rarity) || 99, c.price_diamonds] }
            .map do |c|
      uc = owned[c.id]
      { id: c.id, name: c.name, slot: c.slot, rarity: c.rarity, emoji: c.emoji,
        price: c.price_diamonds, owned: uc.present?, equipped: uc&.equipped || false }
    end
  end

  # Adversaires ciblables par un piège à loup.
  def opponents_json(membership)
    foe = membership&.team&.opponent
    return [] unless foe

    foe.memberships.includes(:user).map { |m| { id: m.id, name: m.display_name } }
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
end
