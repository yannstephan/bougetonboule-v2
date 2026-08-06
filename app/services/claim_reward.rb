# Encaisse un gain en attente (`rewards.claimed_at` nil) : c'est ici que les 💎 et les
# cosmétiques de la série hebdo sont réellement versés, quand le joueur vient les chercher
# sur sa piste. Le job du lundi, lui, ne fait que poser le gain.
#
# Idempotent comme l'ouverture d'un coffre : verrou sur la ligne + relecture de `claimed_at`
# dans la transaction, donc un double-clic (ou deux onglets) ne paie jamais deux fois.
class ClaimReward
  Result = Struct.new(:ok, :message, :gains, keyword_init: true)

  def self.call(membership, reward) = new(membership, reward).call

  def initialize(membership, reward)
    @m = membership
    @r = reward
  end

  def call
    return fail_with("Ce gain n'est pas le tien.") unless @r && @r.membership_id == @m&.id
    return fail_with("Ce gain ne se réclame pas.") unless @r.source.in?(Reward::CLAIMABLE_SOURCES)

    gains = nil
    @r.with_lock do
      return fail_with("Tu as déjà encaissé ce gain.") unless @r.pending?

      gains = credit
      @r.update!(claimed_at: Time.current)
    end
    Result.new(ok: true, message: "Encaissé : #{gains.join(' · ')}", gains:)
  end

  private

  def fail_with(message) = Result.new(ok: false, message:, gains: [])

  def credit
    return credit_diamonds(@r.amount.to_i) if @r.reward_type == "diamonds"

    # Cosmétique tiré au palier : le joueur a pu l'obtenir entre-temps (coffre, boutique).
    # Même compensation que pour un coffre, plutôt qu'un doublon inutile.
    if @m.user.user_cosmetics.exists?(cosmetic_id: @r.cosmetic_id)
      credit_diamonds(GameRules::CHEST_DUPE_DIAMONDS) +
        [ "tu avais déjà #{@r.cosmetic.name}" ]
    else
      UserCosmetic.create!(user: @m.user, cosmetic: @r.cosmetic,
                           acquired_at: Time.current, source_game: @m.game)
      [ "#{@r.cosmetic.emoji} #{@r.cosmetic.name}" ]
    end
  end

  def credit_diamonds(amount)
    @m.user.increment!(:diamonds, amount)
    [ "+#{amount} 💎" ]
  end
end
