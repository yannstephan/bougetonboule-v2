require "test_helper"
require "support/game_setup"

# L'aura est la RÉCOMPENSE d'une panoplie : elle ne s'achète pas, ne tombe d'aucun tirage,
# et arrive toute seule à la dernière pièce. Trois portes à tenir fermées, une à tenir
# ouverte — c'est tout le contrat de la mécanique.
class UnlockSetAuraTest < ActiveSupport::TestCase
  include GameSetup

  setup do
    setup_game
    @user = @membership.user
    @set = CosmeticSet.create!(name: "Panoplie #{SecureRandom.hex(3)}")
    @pieces = %w[hat eyes shoes].map { |slot| piece(slot:) }
    @aura = piece(slot: "aura", price: nil, source: "set")
  end

  def piece(slot:, price: 100, source: "shop", set: @set)
    Cosmetic.create!(name: "Pièce #{SecureRandom.hex(3)}", slot:, rarity: "common",
                     price_diamonds: price, source:, emoji: "🎩", cosmetic_set: set)
  end

  def give(cosmetic) = UserCosmetic.create!(user: @user, cosmetic:, acquired_at: Time.current)

  test "l'aura arrive à la dernière pièce, et pas avant" do
    give(@pieces[0])
    give(@pieces[1])
    assert_not @user.user_cosmetics.exists?(cosmetic: @aura), "débloquée trop tôt"

    give(@pieces[2])
    assert @user.user_cosmetics.exists?(cosmetic: @aura)
  end

  # Le déblocage est accroché à UserCosmetic, pas à l'achat : une pièce arrivée par un coffre
  # ou un cadeau de série doit compter pareil.
  test "peu importe par où la dernière pièce est arrivée" do
    @pieces[0..1].each { |p| give(p) }
    Chest.create!(membership: @membership, rarity: "common", status: "sealed",
                  reward_diamonds: 15, cosmetic: @pieces[2]).open!

    assert @user.user_cosmetics.exists?(cosmetic: @aura)
  end

  test "une aura ne s'achète pas, même en postant son id" do
    @user.update!(diamonds: 5000)
    result = Purchase.cosmetic(@user, @aura)

    assert_not result.ok
    assert_match(/panoplie/, result.message)
    assert_equal 5000, @user.reload.diamonds
  end

  test "une aura ne sort d'aucun tirage" do
    assert_not_includes Cosmetic.drawable, @aura
    assert_includes Cosmetic.drawable, @pieces.first
    # Le coffre, la série et la ligue passent tous par ce scope.
    assert_empty Cosmetic.available.drawable.where(slot: "aura")
  end

  test "compléter la panoplie prévient le joueur" do
    @pieces.each { |p| give(p) }

    notif = @user.notifications.last
    assert_equal "important", notif.importance
    assert_match(/complète/, notif.title)
  end

  test "une panoplie sans aura ne débloque rien et ne casse pas" do
    orpheline = CosmeticSet.create!(name: "Sans aura #{SecureRandom.hex(3)}")
    assert_nothing_raised { give(piece(slot: "hat", set: orpheline)) }
  end

  test "une pièce hors panoplie ne déclenche rien" do
    libre = Cosmetic.create!(name: "Libre #{SecureRandom.hex(3)}", slot: "hat", rarity: "common",
                             price_diamonds: 100, source: "shop", emoji: "🧢")
    assert_nothing_raised { give(libre) }
    assert_not @user.user_cosmetics.exists?(cosmetic: @aura)
  end

  # Deux joueurs, deux collections : compléter chez l'un ne débloque rien chez l'autre.
  test "le déblocage est propre à chaque joueur" do
    @pieces.each { |p| give(p) }
    autre = @foe.user

    assert_not autre.user_cosmetics.exists?(cosmetic: @aura)
  end
end
