# Juge la streak hebdo de chaque participation, le lundi, sur la semaine écoulée
# (lundi → dimanche). Barème et jokers dans GameRules (voir le commentaire là-bas).
#
# Idempotent deux fois : `last_streak_week` (la semaine déjà jugée n'est jamais rejugée)
# et le registre `rewards` (index unique [membership, source, period]) — relancer le job,
# ou le lancer en retard, ne paie jamais deux fois.
class WeeklyStreakJob < ApplicationJob
  queue_as :default

  def perform(week_start = Date.current.beginning_of_week - 7)
    @week_start = week_start.beginning_of_week
    @period = @week_start.strftime("%G-W%V")

    Game.where(status: "active").find_each do |game|
      game.memberships.includes(:user).find_each { |m| judge(m, game) }
    end
  end

  private

  def judge(m, game)
    return if m.last_streak_week == @week_start # déjà jugée

    # Transaction : les 💎, le registre et la série avancent ensemble ou pas du tout.
    ApplicationRecord.transaction do
      if ran?(m)
        reward(m, game)
      elsif m.weekly_streak.positive?
        m.streak_jokers.positive? ? freeze(m, game) : reset(m, game)
      end
      # streak à zéro et semaine sans course : rien à juger, on ne marque même pas la semaine
    end
  rescue ActiveRecord::RecordNotUnique
    # Le registre dit « déjà payé » (marqueur désynchronisé) : on réaligne sans repayer.
    m.update_columns(last_streak_week: @week_start)
  end

  def ran?(m)
    m.trainings.scoring.where(score: 1..)
     .where(date: @week_start.beginning_of_day..(@week_start + 6).end_of_day).exists?
  end

  def reward(m, game)
    streak = m.weekly_streak + 1
    diamonds = GameRules::STREAK_LADDER[[streak, GameRules::STREAK_LADDER.size].min - 1]
    milestone = (streak % GameRules::STREAK_MILESTONE_EVERY).zero?

    # update_columns : le job ne possède que ces compteurs — il ne doit pas revalider
    # le reste du membership (un fruit retiré du catalogue ne doit pas casser les streaks).
    m.update_columns(weekly_streak: streak, best_streak: [streak, m.best_streak].max,
                     last_streak_week: @week_start,
                     streak_jokers: milestone ? [m.streak_jokers + 1, GameRules::STREAK_JOKER_MAX].min : m.streak_jokers)
    GrantReward.give_diamonds(m, diamonds, source: "streak", period: @period)
    gift = milestone ? grant_gift(m) : nil

    extra = [milestone ? "🎁 #{gift}" : nil,
             milestone ? "🧊 +1 joker (#{m.streak_jokers} en réserve)" : nil].compact.join(" · ")
    Notification.create!(
      user: m.user, game:, category: "streak", importance: "important",
      title: "🔥 #{streak} semaine#{"s" if streak > 1} de course d'affilée !",
      body: ["+#{diamonds} 💎", extra.presence].compact.join(" · ")
    )
  end

  # Palier des 5 semaines : un cosmétique pas encore possédé, tiré au sort — comme la
  # récompense de ligue. Inventaire complet → 💎 de repli. Retourne le texte pour la notif.
  def grant_gift(m)
    reward = GrantReward.draw_cosmetic(m, source: "streak_gift", period: @period,
                                          fallback: GameRules::STREAK_GIFT_FALLBACK)
    return GrantReward.label(reward) if reward.cosmetic

    "#{GrantReward.label(reward)} (tu as déjà tous les cosmétiques !)"
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
