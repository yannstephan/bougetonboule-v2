# Encaisse un gain en attente (`rewards.claimed_at` nil) : c'est ici que les 💎 et les
# cosmétiques de la série hebdo sont réellement versés, quand le joueur vient les chercher
# sur sa piste. Le job du lundi, lui, ne fait que poser le gain.
#
# Idempotent comme l'ouverture d'un coffre : verrou sur la ligne + relecture de `claimed_at`
# dans la transaction, donc un double-clic (ou deux onglets) ne paie jamais deux fois.
class ClaimReward
  # `gains` : les phrases du message ; `loot` : les mêmes gains STRUCTURÉS, au format de
  # `Chest#open!` — c'est ce que la révélation du Hub dessine (la pièce, pas une phrase).
  Result = Struct.new(:ok, :message, :gains, :loot, keyword_init: true)

  def self.call(membership, reward) = new(membership, reward).call

  # Le cadeau du palier laisse une TRACE : la révélation du Hub ne dure qu'un instant, et une
  # pièce versée sans être équipée ne se voit nulle part — on ne la retrouvait qu'en fouillant
  # l'armoire au hasard. Secondaire (listée, pas poussée) : le joueur est déjà devant l'écran.
  # Public : on peut la rejouer en console pour un palier encaissé avant qu'elle existe.
  def self.notify_gift(membership, gift)
    cosmetic = gift[:kind] == "cosmetic"
    Notification.create!(
      user: membership.user, game: membership.game, category: "streak", importance: "secondary",
      title: gift_title(gift),
      body: cosmetic ? "Il t'attend dans ton armoire — touche pour l'équiper." : gift[:note],
      link: cosmetic ? "/sac?tab=wardrobe&slot=#{gift[:slot]}" : nil
    )
  end

  # Le titre sert aussi de clé à un rattrapage : c'est lui qui dit « déjà notifié ».
  def self.gift_title(gift)
    gift[:kind] == "cosmetic" ? "🎁 Cadeau de série : #{gift[:emoji]} #{gift[:name]}" : "🎁 Cadeau de série : +#{gift[:amount]} 💎"
  end

  def initialize(membership, reward)
    @m = membership
    @r = reward
  end

  def call
    return fail_with("Ce gain n'est pas le tien.") unless @r && @r.membership_id == @m&.id
    return fail_with("Ce gain ne se réclame pas.") unless @r.source.in?(Reward::CLAIMABLE_SOURCES)

    loot = nil
    @r.with_lock do
      return fail_with("Tu as déjà encaissé ce gain.") unless @r.pending?

      loot = credit
      @r.update!(claimed_at: Time.current)
      self.class.notify_gift(@m, loot.first) if @r.source == "streak_gift"
    end
    gains = loot.map { |g| label(g) }
    Result.new(ok: true, message: "Encaissé : #{gains.join(' · ')}", gains:, loot:)
  end

  private

  def fail_with(message) = Result.new(ok: false, message:, gains: [], loot: [])

  def credit
    return credit_diamonds(@r.amount.to_i) if @r.reward_type == "diamonds"

    # Cosmétique tiré au palier : le joueur a pu l'obtenir entre-temps (coffre, boutique).
    # Même compensation que pour un coffre, plutôt qu'un doublon inutile.
    if @m.user.user_cosmetics.exists?(cosmetic_id: @r.cosmetic_id)
      credit_diamonds(GameRules::CHEST_DUPE_DIAMONDS, note: "tu avais déjà #{@r.cosmetic.name}")
    else
      c = @r.cosmetic
      UserCosmetic.create!(user: @m.user, cosmetic: c, acquired_at: Time.current, source_game: @m.game)
      [ { kind: "cosmetic", name: c.name, emoji: c.emoji, art: c.art, rarity: c.rarity, slot: c.slot } ]
    end
  end

  def credit_diamonds(amount, note: nil)
    @m.user.increment!(:diamonds, amount)
    [ { kind: "diamonds", amount:, note: }.compact ]
  end

  def label(g)
    g[:kind] == "cosmetic" ? "#{g[:emoji]} #{g[:name]}" : [ "+#{g[:amount]} 💎", g[:note] ].compact.join(" · ")
  end
end
