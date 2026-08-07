require "test_helper"

# Les PANOPLIES et leurs PROMOTIONS. Deux contrats à tenir :
#   1. une panoplie est d'UNE rareté — c'est ce qui rend son prix lisible d'un coup d'œil ;
#   2. une promo ne touche JAMAIS au prix catalogue. Elle est recalculée à la volée, donc
#      la retirer rétablit les prix d'origine toute seule et rien ne peut « rester soldé ».
class CosmeticSetTest < ActiveSupport::TestCase
  def set(**attrs) = CosmeticSet.create!({ name: "Panoplie #{SecureRandom.hex(3)}" }.merge(attrs))

  def piece(panoplie, price: 100, rarity: "common", **attrs)
    Cosmetic.create!({ name: "Pièce #{SecureRandom.hex(3)}", slot: "hat", rarity:,
                       price_diamonds: price, source: "shop", emoji: "🎧",
                       cosmetic_set: panoplie }.merge(attrs))
  end

  test "hors promo, on paie le prix catalogue" do
    p = piece(set)
    assert_equal 100, p.current_price
    assert_not p.on_promo?
  end

  test "une promo en cours fait tomber le prix de toutes les pièces" do
    s = set(promo_percent: 20, promo_from: 2.days.ago, promo_until: 2.days.from_now)
    assert_equal 80, piece(s).current_price
    assert_equal 200, piece(s, price: 250).current_price
    assert piece(s).on_promo?
  end

  test "le prix promo est arrondi au multiple de 5 — une boutique n'affiche pas 72 💎" do
    s = set(promo_percent: 20)
    assert_equal 70, piece(s, price: 90).current_price   # 72 → 70
    assert_equal 90, piece(s, price: 110).current_price  # 88 → 90
  end

  test "une promo pas encore commencée ou déjà finie ne s'applique pas" do
    avant = set(promo_percent: 50, promo_from: 3.days.from_now)
    apres = set(promo_percent: 50, promo_until: 3.days.ago)

    assert_equal 100, piece(avant).current_price
    assert_equal 100, piece(apres).current_price
    assert_not avant.promo?
    assert_not apres.promo?
  end

  test "sans dates, une promo court sans borne" do
    s = set(promo_percent: 50)
    assert s.promo?
    assert_nil s.promo_days_left
    assert_equal 50, piece(s).current_price
  end

  test "retirer le pourcentage rétablit les prix, sans rien réécrire" do
    s = set(promo_percent: 30)
    p = piece(s)
    assert_equal 70, p.current_price

    s.update!(promo_percent: nil)
    assert_equal 100, p.reload.current_price
    # Le prix catalogue n'a jamais bougé — c'est tout l'intérêt.
    assert_equal 100, p.price_diamonds
  end

  test "une pièce d'une autre rareté est refusée dans la panoplie" do
    s = set
    piece(s, rarity: "common")
    intruse = Cosmetic.new(name: "Intruse", slot: "eyes", rarity: "epic", price_diamonds: 500,
                           source: "shop", emoji: "🕶️", cosmetic_set: s)

    assert_not intruse.valid?
    assert_match(/common/, intruse.errors[:rarity].to_sentence)
  end

  test "un pourcentage hors de 1..90 est refusé" do
    assert_not CosmeticSet.new(name: "A", promo_percent: 0).valid?
    assert_not CosmeticSet.new(name: "B", promo_percent: 95).valid?
  end

  test "une fenêtre à l'envers est refusée" do
    s = CosmeticSet.new(name: "C", promo_percent: 20,
                        promo_from: 1.day.from_now, promo_until: 1.day.ago)
    assert_not s.valid?
  end

  # Le prix débité est relu au moment de l'achat : un onglet resté ouvert pendant que la
  # promo se termine ne paie pas l'ancien prix.
  test "Purchase débite le prix promo, pas le prix catalogue" do
    s = set(promo_percent: 40)
    p = piece(s, price: 100)
    user = User.create!(firstname: "Test", email: "promo-#{SecureRandom.hex(4)}@btb.test",
                        password: "odyssea2027", diamonds: 60)

    assert Purchase.cosmetic(user, p).ok
    assert_equal 0, user.reload.diamonds
  end

  test "Purchase refuse si le solde ne couvre pas le prix promo" do
    s = set(promo_percent: 10)
    p = piece(s, price: 100)
    user = User.create!(firstname: "Test", email: "promo-#{SecureRandom.hex(4)}@btb.test",
                        password: "odyssea2027", diamonds: 80)

    result = Purchase.cosmetic(user, p)
    assert_not result.ok
    assert_equal 80, user.reload.diamonds
  end
end
