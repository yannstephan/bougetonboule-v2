require "test_helper"
require "support/game_setup"

# Régression : un joueur encaissait son cadeau de palier et ne le trouvait nulle part. Le
# message de confirmation partait vers un Hub qui ne l'affichait pas, aucune notification
# n'en gardait la trace, et la pièce dormait dans l'armoire sans être équipée.
class StreakGiftRevealTest < ActionDispatch::IntegrationTest
  include GameSetup

  setup do
    setup_game
    @user = @membership.user
    @bowtie = Cosmetic.create!(name: "Nœud test", slot: "neck", rarity: "legendary", emoji: "🎀")
    @week = GameRules::STREAK_MILESTONE_EVERY
    Reward.create!(user: @user, membership: @membership, amount: 50, streak_week: @week,
                   reward_type: "diamonds", source: "streak", period: "2026-W45")
    Reward.create!(user: @user, membership: @membership, cosmetic: @bowtie, streak_week: @week,
                   reward_type: "cosmetic", source: "streak_gift", period: "2026-W45")
    post "/login", params: { email: @user.email, password: "odyssea2027" }
  end

  test "le cadeau du palier se révèle sur le Hub, avec la pièce et sa rareté" do
    post "/serie/#{@week}/reclamer"

    reveal = flash[:chest]
    assert reveal, "le palier doit passer par la révélation, pas par un message d'une ligne"
    assert_equal "legendary", reveal[:rarity], "la couleur est celle de la pièce offerte"
    cosmetic = reveal[:gains].find { |g| g[:kind] == "cosmetic" }
    assert_equal "Nœud test", cosmetic[:name]
    assert_equal "neck", cosmetic[:slot], "« L'équiper → » doit ouvrir le bon rayon"
    assert reveal[:gains].any? { |g| g[:kind] == "diamonds" && g[:amount] == 50 }
    assert @user.user_cosmetics.exists?(cosmetic: @bowtie)
  end

  test "une notification garde la trace du cadeau et mène au rayon de la pièce" do
    post "/serie/#{@week}/reclamer"

    notif = @user.notifications.find_by!(category: "streak", importance: "secondary")
    assert_includes notif.title, "Nœud test"
    assert_equal "/sac?tab=wardrobe&slot=neck", notif.link
    assert_includes @user.notifications.listed, notif
  end

  test "une semaine sans cadeau garde son simple message" do
    Reward.where(source: "streak_gift").delete_all
    post "/serie/#{@week}/reclamer"

    assert_nil flash[:chest]
    assert_match "+50 💎", flash[:notice]
    assert_not @user.notifications.exists?(importance: "secondary", category: "streak")
  end

  test "l'armoire s'ouvre sur le rayon demandé, et ignore un rayon inconnu" do
    get "/sac", params: { tab: "wardrobe", slot: "neck" }
    assert_match %r{"initial_slot":"neck"}, response.body.gsub("&quot;", '"')

    get "/sac", params: { tab: "wardrobe", slot: "pantalon" }
    assert_match %r{"initial_slot":null}, response.body.gsub("&quot;", '"')
  end
end
