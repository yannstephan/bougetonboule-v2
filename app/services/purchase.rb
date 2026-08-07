# Achats à la boutique. Deux monnaies étanches (règle d'or : jamais de pay-to-win) :
#   - les OBJETS (power-ups) s'achètent en 🍑 boules (Membership.balls, par partie) ;
#   - les COSMÉTIQUES s'achètent en 💎 diamants (User.diamonds, global) et ne touchent
#     qu'à l'apparence.
# On n'achète jamais de boules, ni d'avantage de combat avec des diamants.
class Purchase
  Result = Struct.new(:ok, :message, keyword_init: true)

  # Achète un objet à usage unique, déposé dans l'inventaire de la participation.
  def self.item(membership, item)
    return err("Rejoins une partie pour acheter des objets.") unless membership
    return err("Pas assez de boules 🍑") if membership.balls < item.price

    MembershipItem.transaction do
      membership.update!(balls: membership.balls - item.price)
      membership.membership_items.create!(item:)
    end
    ok("#{item.name} ajouté à ton inventaire !")
  end

  # Achète un cosmétique, déposé dans l'armoire (globale) du joueur.
  # ⚠️ Le prix débité est `current_price`, pas `price_diamonds` : c'est le prix catalogue
  # MOINS la promo de sa panoplie, si elle court à cet instant. On le relit ici et pas
  # côté client — une promo terminée pendant qu'un onglet traînait ouvert se paie plein pot.
  def self.cosmetic(user, cosmetic, source_game: nil)
    # Une aura ne s'achète pas : elle est offerte quand on complète sa panoplie (UnlockSetAura).
    return err("Une aura ne s'achète pas : complète sa panoplie.") if cosmetic.aura?
    return err("Ce cosmétique n'est pas en vente.") if cosmetic.price_diamonds.nil?
    return err("#{cosmetic.name} n'est plus disponible.") unless cosmetic.available?
    return err("Tu possèdes déjà #{cosmetic.name}.") if user.user_cosmetics.exists?(cosmetic_id: cosmetic.id)

    price = cosmetic.current_price
    return err("Pas assez de diamants 💎") if user.diamonds < price

    UserCosmetic.transaction do
      user.update!(diamonds: user.diamonds - price)
      user.user_cosmetics.create!(cosmetic:, acquired_at: Time.current, source_game:)
    end
    ok("#{cosmetic.name} ajouté à ton armoire !")
  end

  def self.ok(msg)  = Result.new(ok: true, message: msg)
  def self.err(msg) = Result.new(ok: false, message: msg)
end
