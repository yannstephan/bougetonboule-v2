require "test_helper"
require "support/game_setup"

# Le back-office est réservé à l'organisateur de la partie (Membership#admin?).
class AdminTest < ActionDispatch::IntegrationTest
  include GameSetup

  setup do
    setup_game
    @membership.update!(role: "admin")
    @cosmetic = Cosmetic.create!(name: "Pièce test", slot: "hat", rarity: "common",
                                 price_diamonds: 100, source: "shop", emoji: "🎩")
  end

  def login_as(membership)
    post login_path, params: { email: membership.user.email, password: "odyssea2027" }
  end

  test "un joueur ordinaire est renvoyé à l'accueil" do
    login_as(@foe)
    get admin_path

    assert_redirected_to root_path
    assert_match(/organisateur/i, flash[:alert])
  end

  test "un visiteur non connecté est renvoyé vers la connexion" do
    get admin_path
    assert_response :redirect
    assert_no_match(/\/admin/, response.location)
  end

  test "l'organisateur ouvre le back-office" do
    login_as(@membership)
    get admin_path
    assert_response :success
  end

  test "l'organisateur crée puis supprime une journée spéciale" do
    login_as(@membership)

    assert_difference -> { @game.special_days.count }, 1 do
      post admin_special_days_path, params: { name: "Halloween", date: "2026-10-31", multiplier: 2 }
    end
    day = @game.special_days.last
    assert_equal Date.new(2026, 10, 31), day.date

    assert_difference -> { @game.special_days.count }, -1 do
      delete admin_special_day_path(day)
    end
  end

  test "l'organisateur pose une fenêtre de disponibilité" do
    login_as(@membership)
    patch admin_cosmetic_path(@cosmetic), params: { available_from: "2026-10-15", available_until: "2026-11-05" }

    @cosmetic.reload
    assert @cosmetic.seasonal?
    assert_equal Date.new(2026, 10, 15), @cosmetic.available_from.to_date
    # La borne de fin court jusqu'au bout de la journée, sinon la pièce expire à minuit pile.
    assert_equal Date.new(2026, 11, 5), @cosmetic.available_until.to_date
    assert @cosmetic.available_until.hour >= 23
  end

  test "des dates vides remettent la pièce en permanence" do
    @cosmetic.update!(available_from: 1.week.ago, available_until: 1.week.from_now)
    login_as(@membership)

    patch admin_cosmetic_path(@cosmetic), params: { available_from: "", available_until: "" }

    assert_not @cosmetic.reload.seasonal?
  end

  test "une fenêtre à l'envers est refusée" do
    login_as(@membership)
    patch admin_cosmetic_path(@cosmetic), params: { available_from: "2026-11-05", available_until: "2026-10-15" }

    assert_not @cosmetic.reload.seasonal?
    assert_match(/après/i, flash[:alert])
  end
end
