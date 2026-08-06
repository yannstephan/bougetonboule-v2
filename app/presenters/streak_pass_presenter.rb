# La piste de la série hebdo, façon season pass : un CYCLE DE 5 SEMAINES qui se termine
# toujours sur le gros lot (🎁 cosmétique + 🧊 joker), puis se rejoue.
#
# Pourquoi un cycle plutôt que l'échelle 1→5 : la série n'a pas de fin (plateau à 50 💎 après
# la 5e semaine) alors qu'un season pass a une piste finie. Le cycle rend la piste finie sans
# mentir : il y a toujours un palier à atteindre, et il reste lisible à la 47e semaine.
#
#   série 0  → cycle 1..5      série 5 → cycle 6..10      série 6 → cycle 6..10
#
# Quatre états par nœud :
#   claimed   — semaine acquise et déjà encaissée
#   claimable — semaine acquise, le gain attend (bouton « Réclamer »)
#   next      — la semaine en cours, celle qu'une sortie déclenche
#   locked    — plus loin sur la piste
class StreakPassPresenter
  def self.call(membership) = new(membership).call

  def initialize(membership)
    @m = membership
    @size = GameRules::STREAK_MILESTONE_EVERY
  end

  def call
    {
      weeks: @m.weekly_streak,
      best: @m.best_streak,
      jokers: @m.streak_jokers,
      joker_max: GameRules::STREAK_JOKER_MAX,
      # Déduit de `cycle_start` et pas de la série, sinon le numéro annonce le cycle suivant
      # alors que la piste montre encore celui qu'on est en train de finir.
      cycle: (cycle_start - 1) / @size + 1,
      # Ce qu'il reste à courir avant le palier — l'argument qui fait sortir courir.
      to_milestone: cycle_end - @m.weekly_streak,
      ran_this_week: ran_this_week?,
      nodes: (cycle_start..cycle_end).map { |w| node(w) }
    }
  end

  private

  # ⚠️ `- 1` : à la 5e semaine on est encore SUR le cycle 1..5, pas déjà sur le suivant.
  # Sans ça, le palier qu'on vient de gagner sortait de la piste avant d'avoir été encaissé.
  def cycle_start
    return 1 if @m.weekly_streak.zero?

    ((@m.weekly_streak - 1) / @size) * @size + 1
  end

  def cycle_end = cycle_start + @size - 1

  def node(week)
    pending = pending_by_week[week] || []
    {
      week:,
      diamonds: GameRules::STREAK_LADDER[[ week, GameRules::STREAK_LADDER.size ].min - 1],
      milestone: (week % @size).zero?,
      state: state_for(week, pending),
      # Un palier peut avoir DEUX gains en attente (les 💎 et le cadeau) : le bouton les
      # encaisse d'un coup, sinon le cadeau resterait en rade.
      pending: pending.size
    }
  end

  def state_for(week, pending)
    return "claimable" if pending.any?
    return "claimed" if week <= @m.weekly_streak
    return "next" if week == @m.weekly_streak + 1

    "locked"
  end

  # Les gains de série en attente, groupés par semaine de série (💎 et cadeau ensemble).
  def pending_by_week
    @pending_by_week ||= @m.rewards.pending.streak.group_by(&:streak_week)
  end

  # Semaine en cours déjà sécurisée ? Depuis qu'AdvanceStreak avance la série à l'import,
  # le marqueur suffit — pas besoin de retourner voir les courses.
  def ran_this_week?
    @m.last_streak_week == Date.current.beginning_of_week
  end
end
