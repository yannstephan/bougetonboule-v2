class ShopController < ApplicationController
  before_action :require_authentication

  def index
    m = current_membership
    render inertia: "Boutique", props: {
      has_team: m.present?,
      balls: m&.balls || 0,
      items: items_json(m),
      cosmetics: cosmetics_json,
      inventory: inventory_json(m),
      opponents: opponents_json(m),
      team_names: m && { mine: m.team.name, foe: m.team.opponent&.name }
    }
  end

  # Achat d'un objet en 🍑 (dépend de la participation).
  def buy_item
    result = Purchase.item(current_membership, Item.find(params[:item_id]))
    redirect_with result, to: shop_path
  end

  # Achat d'un cosmétique en 💎 (global).
  def buy_cosmetic
    result = Purchase.cosmetic(current_user, Cosmetic.find(params[:cosmetic_id]),
                               source_game: current_membership&.game)
    redirect_with result, to: shop_path
  end

  # Utiliser un objet de l'inventaire (à usage unique) — réutilise la logique de combat.
  def use_item
    m = current_membership
    return redirect_to shop_path, alert: "Aucune partie active." unless m

    result = PerformAction.call(m, action_type: "use_item", item_id: params[:item_id],
                                   target_id: params[:target_id], target_team: params[:target_team])
    redirect_with result, to: shop_path
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
            .sort_by { |c| [Cosmetic::RARITIES.index(c.rarity) || 99, c.price_diamonds] }
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

    MembershipPresenter.options(foe.memberships.includes(:user))
  end

  # Objets possédés (non utilisés), regroupés par type avec leur nombre.
  def inventory_json(membership)
    return [] unless membership

    membership.membership_items.unused.includes(:item)
              .group_by(&:item_id).map do |_item_id, rows|
      item = rows.first.item
      { item_id: item.id, name: item.name, description: item.description,
        effect_type: item.effect_type, count: rows.size }
    end
  end
end
