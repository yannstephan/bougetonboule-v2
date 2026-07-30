require "test_helper"

# La boutique de saison : une pièce peut n'exister qu'un temps (`available_from` /
# `available_until`). Hors fenêtre elle doit disparaître de PARTOUT — vente et tirages.
class CosmeticSeasonalTest < ActiveSupport::TestCase
  def cosmetic(**attrs)
    Cosmetic.create!({ name: "Pièce #{SecureRandom.hex(3)}", slot: "hat", rarity: "common",
                       price_diamonds: 100, source: "shop", emoji: "🎩" }.merge(attrs))
  end

  test "sans fenêtre, une pièce est toujours disponible" do
    piece = cosmetic
    assert piece.available?
    assert_not piece.seasonal?
    assert_nil piece.days_left
    assert_includes Cosmetic.available, piece
  end

  test "une pièce dont la fenêtre est passée sort du catalogue" do
    piece = cosmetic(available_from: 3.weeks.ago, available_until: 1.week.ago)
    assert_not piece.available?
    assert piece.seasonal?
    assert_not_includes Cosmetic.available, piece
    assert_includes Cosmetic.seasonal, piece
  end

  test "une pièce dont la fenêtre n'est pas ouverte sort du catalogue" do
    piece = cosmetic(available_from: 1.week.from_now)
    assert_not piece.available?
    assert_not_includes Cosmetic.available, piece
  end

  test "days_left compte les jours restants et plafonne à 0" do
    assert_equal 3, cosmetic(available_until: 3.days.from_now).days_left
    assert_equal 0, cosmetic(available_until: 2.hours.from_now).days_left
    assert_equal 0, cosmetic(available_until: 1.day.ago).days_left
  end

  test "l'achat d'une pièce hors fenêtre est refusé" do
    user = User.create!(firstname: "Test", email: "saison@btb.test", password: "odyssea2027", diamonds: 5_000)
    piece = cosmetic(available_until: 1.day.ago)

    result = Purchase.cosmetic(user, piece)

    assert_not result.ok
    assert_equal 5_000, user.reload.diamonds
    assert_not user.user_cosmetics.exists?(cosmetic_id: piece.id)
  end

  test "l'achat d'une pièce dans sa fenêtre passe" do
    user = User.create!(firstname: "Test", email: "saison2@btb.test", password: "odyssea2027", diamonds: 5_000)
    piece = cosmetic(available_from: 1.day.ago, available_until: 1.day.from_now)

    assert Purchase.cosmetic(user, piece).ok
    assert user.user_cosmetics.exists?(cosmetic_id: piece.id)
  end
end
