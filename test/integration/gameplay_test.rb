require "test_helper"

# Boucle de jeu complète, du bout des doigts du joueur : acheter, utiliser, attaquer,
# soigner, discuter.
class GameplayTest < ActionDispatch::IntegrationTest
  setup do
    @game = create_game
    @exo, @red = @game.teams.to_a
    @me = create_player(@game, @exo, firstname: "Yann", balls: 50)
    @foe = create_player(@game, @red, firstname: "Chloé", balls: 50)
    sign_in_as(@me.user)
  end

  test "attaquer entame le monstre adverse et coûte une boule" do
    with_rule(:CRIT_FAIL_CHANCE, 0.0) do
      assert_difference -> { @red.monster.reload.hp }, -GameRules::BASE_POWER do
        post actions_path, params: { action_type: "attack" }
      end
    end
    assert_redirected_to combat_path
    assert_equal 49, @me.reload.balls
  end

  test "une attaque ratée ne fait aucun dégât mais mord le porte-monnaie" do
    with_rule(:CRIT_FAIL_CHANCE, 1.0) do
      assert_no_difference -> { @red.monster.reload.hp } do
        post actions_path, params: { action_type: "attack" }
      end
    end
    assert_operator @me.reload.balls, :<, 50
    assert_match(/critique/i, flash[:alert])
  end

  test "soigner rend des PV à son propre monstre" do
    @exo.monster.update!(hp: 5_000)

    assert_difference -> { @exo.monster.reload.hp }, GameRules::BASE_POWER do
      post actions_path, params: { action_type: "heal" }
    end
    assert_equal 50 - GameRules::HEAL_COST, @me.reload.balls
  end

  test "on ne peut pas attaquer un monstre protégé" do
    @red.monster.update!(protected_until: 1.hour.from_now)

    assert_no_difference -> { @red.monster.reload.hp } do
      post actions_path, params: { action_type: "attack" }
    end
    assert_match(/protégé/, flash[:alert])
  end

  test "le combat est verrouillé quand la partie est terminée" do
    @game.update!(status: "finished")

    result = nil
    assert_no_difference -> { @red.monster.reload.hp } do
      result = PerformAction.call(@me, action_type: "attack")
    end
    assert_not result.ok
    assert_match(/terminée/, result.message)
  end

  test "acheter puis utiliser un bouclier protège son monstre" do
    shield = Item.create!(name: "Bouclier", effect_type: "shield", price: 6)

    assert_difference -> { @me.membership_items.unused.count }, 1 do
      post buy_item_path, params: { item_id: shield.id }
    end
    assert_equal 44, @me.reload.balls

    post use_item_path, params: { item_id: shield.id }
    assert @exo.monster.reload.protected?
    assert_equal 0, @me.membership_items.unused.count
  end

  test "un achat trop cher est refusé proprement" do
    @me.update!(balls: 1)
    pricey = Item.create!(name: "Bouclier", effect_type: "shield", price: 6)

    assert_no_difference -> { @me.membership_items.count } do
      post buy_item_path, params: { item_id: pricey.id }
    end
    assert_match(/Pas assez/, flash[:alert])
  end

  test "acheter un cosmétique le dépose dans l'armoire" do
    @me.user.update!(diamonds: 300)
    hat = Cosmetic.create!(name: "Casquette", slot: "hat", rarity: "rare", price_diamonds: 250, emoji: "🧢")

    post buy_cosmetic_path, params: { cosmetic_id: hat.id }
    assert @me.user.user_cosmetics.exists?(cosmetic: hat)
    assert_equal 50, @me.user.reload.diamonds

    post equip_avatar_path, params: { cosmetic_id: hat.id, equipped: true }
    assert @me.user.user_cosmetics.find_by(cosmetic: hat).equipped
  end

  test "un message d'équipe notifie les coéquipiers, le général ne notifie personne" do
    mate = create_player(@game, @exo, firstname: "Inès")
    team_conv = @game.conversations.team_chats.find_by(team: @exo)

    assert_difference -> { mate.user.notifications.count }, 1 do
      post conversation_messages_path(team_conv), params: { body: "On attaque ce soir" }
    end

    assert_no_difference -> { Notification.count } do
      post conversation_messages_path(@game.conversations.general.first), params: { body: "Salut" }
    end
  end

  test "on ne peut pas écrire dans le chat de l'équipe adverse" do
    foe_conv = @game.conversations.team_chats.find_by(team: @red)

    assert_no_difference -> { Message.count } do
      post conversation_messages_path(foe_conv), params: { body: "Espionnage" }
    end
    assert_response :forbidden
  end

  test "on choisit un fruit de sa famille, pas celui d'en face" do
    patch avatar_path, params: { fruit: "mangue" }
    assert_equal "mangue", @me.reload.fruit

    patch avatar_path, params: { fruit: "fraise" }
    assert_equal "mangue", @me.reload.fruit
    assert_match(/pas disponible/, flash[:alert])
  end

  test "ouvrir un coffre crédite les diamants une seule fois" do
    chest = @me.chests.create!(rarity: "rare", reward_diamonds: 30)

    assert_difference -> { @me.user.reload.diamonds }, 30 do
      post open_chest_path(chest)
    end
    assert_redirected_to root_path

    assert_no_difference -> { @me.user.reload.diamonds } do
      post open_chest_path(chest)
    end
  end
end
