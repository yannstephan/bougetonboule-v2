# Décerne la récompense du 1er du classement mensuel : un cosmétique tiré au hasard
# parmi ceux qu'il ne possède pas encore.
#
# Idempotent : la récompense est enregistrée dans `rewards` avec la période ("2026-07"),
# sous index unique — rejouer le mois ne décerne jamais deux fois le titre.
class AwardMonthlyLeague
  FALLBACK_DIAMONDS = 100 # si le gagnant possède déjà tous les cosmétiques

  Result = Struct.new(:awarded, :reason, :reward, keyword_init: true)

  def self.call(game, month = Date.current.prev_month) = new(game, month).call

  def initialize(game, month)
    @game = game
    @month = month.beginning_of_month
    @period = @month.strftime("%Y-%m")
  end

  def call
    winner = LeagueStandings.month(@game, @month).winner
    return skip("personne n'a couru ce mois-ci") unless winner
    return skip("déjà décerné") if already_awarded?(winner.membership)

    reward = grant(winner)
    notify(winner, reward)
    Result.new(awarded: true, reward:)
  end

  private

  def skip(reason) = Result.new(awarded: false, reason:)
  def month_name = HumanDates.month_name(@month)

  def already_awarded?(membership)
    Reward.exists?(membership:, source: "rank", period: @period)
  end

  def grant(winner)
    GrantReward.draw_cosmetic(winner.membership, source: "rank", period: @period,
                                                 fallback: FALLBACK_DIAMONDS)
  end

  def prize_text(reward)
    return "Tu remportes #{GrantReward.label(reward)} !" if reward.cosmetic

    "Tu as déjà tous les cosmétiques — voilà #{reward.amount} 💎 à la place !"
  end

  def notify(winner, reward)
    prize = prize_text(reward)

    Notification.create!(
      user: winner.membership.user, game: @game, category: "league", importance: "important",
      title: "🏆 1er du classement de #{month_name} !",
      body: "#{winner.score.round(1)} 🍑 sur le mois. #{prize}",
      payload: { period: @period, rank: 1, score: winner.score,
                 reward_type: reward.reward_type, cosmetic: reward.cosmetic&.name }
    )
  end
end
