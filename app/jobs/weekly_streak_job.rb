# Filet de sécurité hebdomadaire de la série. Depuis que courir sécurise la semaine **dès
# l'import** (voir AdvanceStreak, appelé par ImportTraining), ce job n'a plus que deux rôles :
#
#   1. sanctionner les semaines SANS course — consommer un joker (gel) ou remettre à zéro ;
#   2. rattraper une semaine avec course que l'import a ratée (réconciliation tardive,
#      historique d'avant cette bascule). AdvanceStreak est idempotent, donc sans effet si
#      la semaine a déjà été acquise.
#
# Tourne le lundi et juge la semaine écoulée (lundi → dimanche).
class WeeklyStreakJob < ApplicationJob
  queue_as :default

  def perform(week_start = Date.current.beginning_of_week - 7)
    @week_start = week_start.beginning_of_week

    Game.where(status: "active").find_each do |game|
      game.memberships.includes(:user).find_each { |m| judge(m, game) }
    end
  end

  private

  def judge(m, game)
    return if m.last_streak_week && m.last_streak_week >= @week_start # déjà acquise

    if ran?(m)
      AdvanceStreak.for_week(m, @week_start)
    elsif m.weekly_streak.positive?
      ApplicationRecord.transaction do
        m.streak_jokers.positive? ? freeze(m, game) : reset(m, game)
      end
    end
    # série à zéro et semaine sans course : rien à juger, on ne marque même pas la semaine
  end

  # Même règle que l'import : une sortie suffit, ce qu'elle rapporte n'entre pas en compte.
  def ran?(m)
    m.trainings.real.where(date: @week_start.beginning_of_day..(@week_start + 6).end_of_day).exists?
  end

  def freeze(m, game)
    m.update_columns(streak_jokers: m.streak_jokers - 1, last_streak_week: @week_start)
    Notification.create!(
      user: m.user, game:, category: "streak", importance: "important",
      title: "🧊 Joker consommé !",
      body: "Pas de course cette semaine — ta série de #{m.weekly_streak} semaines est gelée. " \
            "Reste #{m.streak_jokers} joker#{"s" if m.streak_jokers > 1}."
    )
  end

  def reset(m, game)
    lost = m.weekly_streak
    m.update_columns(weekly_streak: 0, last_streak_week: @week_start)
    Notification.create!(
      user: m.user, game:, category: "streak", importance: "important",
      title: "💔 Série perdue",
      body: "Pas de course cette semaine et plus de joker : ta série de #{lost} semaine#{"s" if lost > 1} " \
            "repart à zéro. Une sortie et c'est reparti !"
    )
  end
end
