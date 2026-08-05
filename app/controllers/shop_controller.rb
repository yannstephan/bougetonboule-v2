class ShopController < ApplicationController
  before_action :require_authentication

  RARITY_ORDER = %w[common rare epic legendary].freeze

  def index
    # Le sac a quitté la boutique pour son propre onglet : les vieux liens y suivent.
    return redirect_to inventory_path if params[:tab] == "inventory"

    m = current_membership
    render inertia: "Boutique", props: {
      has_team: m.present?,
      initial_tab: params[:tab] == "cosmetics" ? "cosmetics" : "items",
      balls: m&.balls || 0,
      items: items_json(m),
      cosmetics: cosmetics_json,
      seasonal: seasonal_json
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

  private

  def items_json(membership)
    owned = membership ? membership.membership_items.unused.group(:item_id).count : {}
    Item.not_miscellaneous.order(:price).map do |item|
      { id: item.id, name: item.name, description: item.description,
        effect_type: item.effect_type, price: item.price, owned: owned[item.id] || 0 }
    end
  end

  # Le rayon permanent : ce qui est en vente et n'a pas de date de fin.
  def cosmetics_json = serialize_cosmetics(Cosmetic.purchasable.available.where(available_until: nil))

  # La BOUTIQUE DE SAISON : les pièces en vente dont la fenêtre se referme. Servies à part
  # pour être mises en avant, avec le nombre de jours restants sur chaque carte.
  def seasonal_json = serialize_cosmetics(Cosmetic.purchasable.available.where.not(available_until: nil))

  def serialize_cosmetics(scope)
    owned = current_user.user_cosmetics.includes(:cosmetic).index_by(&:cosmetic_id)
    scope.sort_by { |c| [ RARITY_ORDER.index(c.rarity) || 99, c.price_diamonds ] }.map do |c|
      uc = owned[c.id]
      { id: c.id, name: c.name, slot: c.slot, rarity: c.rarity, emoji: c.emoji, art: c.art,
        price: c.price_diamonds, owned: uc.present?, equipped: uc&.equipped || false,
        days_left: c.days_left }
    end
  end
end
