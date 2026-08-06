# Fait avancer la série d'une semaine et POSE les gains en attente (le joueur les encaisse
# ensuite sur sa piste, voir ClaimReward).
#
# ⚠️ La semaine est acquise **dès l'import de la course**, pas le lundi suivant : courir, c'est
# débloquer son palier tout de suite. Deux appelants, donc, et c'est voulu :
#   - `ImportTraining` → `for_training`, le chemin normal, immédiat ;
#   - `WeeklyStreakJob` → `for_week`, filet de sécurité le lundi (course importée par la
#     réconciliation, semaine que l'import a ratée, historique d'avant cette bascule).
#
# Trois garde-fous rendent le double appel inoffensif :
#   1. `last_streak_week` — une semaine déjà acquise n'est jamais recomptée ;
#   2. l'index unique `rewards[membership, source, period]` — le gain ne peut pas exister deux fois ;
#   3. la transaction — compteurs, registre et notification avancent ensemble ou pas du tout.
class AdvanceStreak
  # Depuis une course : c'est la semaine de la COURSE qui compte, pas celle du jour. Une sortie
  # de mardi importée le dimanche sécurise bien la semaine de mardi.
  #
  # ⚠️ La PREMIÈRE course suffit, quel que soit ce qu'elle rapporte. On ne regarde pas le score :
  #   - une 2e sortie du jour vaut 0 🍑 (plafond journalier) mais reste une sortie ;
  #   - une course piégée vaut 0 🍑 — le loup vole les boules de la course, il n'a pas à
  #     casser une série de 20 semaines pour 5 🍑.
  # Seule une course refusée par l'anti-triche ne compte pas : elle n'existe pas pour le jeu.
  def self.for_training(training)
    return unless training.real?

    for_week(training.membership, training.date.to_date.beginning_of_week)
  end

  def self.for_week(membership, week_start) = new(membership, week_start).call

  def initialize(membership, week_start)
    @m = membership
    @week = week_start
  end

  def call
    # `>=` et pas `==` : une course arrivée en retard ne peut pas rouvrir une semaine déjà
    # jugée (le lundi a pu y consommer un joker — on ne rejoue pas l'histoire).
    return false if @m.last_streak_week && @m.last_streak_week >= @week

    ApplicationRecord.transaction { grant }
    true
  rescue ActiveRecord::RecordNotUnique
    # Le registre dit « déjà posé » (marqueur désynchronisé) : on réaligne sans reposer.
    @m.update_columns(last_streak_week: @week)
    false
  end

  private

  def period = @week.strftime("%G-W%V")

  def grant
    streak = @m.weekly_streak + 1
    diamonds = GameRules::STREAK_LADDER[[ streak, GameRules::STREAK_LADDER.size ].min - 1]
    milestone = (streak % GameRules::STREAK_MILESTONE_EVERY).zero?

    # update_columns : ce service ne possède que ces compteurs — il ne doit pas revalider le
    # reste du membership (un fruit retiré du catalogue ne doit pas casser les séries).
    # Le JOKER, lui, tombe tout de suite : c'est un bouclier, pas un cadeau. Le faire attendre
    # ferait perdre leur série à ceux qui n'ouvrent pas l'app à temps.
    @m.update_columns(weekly_streak: streak, best_streak: [ streak, @m.best_streak ].max,
                      last_streak_week: @week,
                      streak_jokers: milestone ? [ @m.streak_jokers + 1, GameRules::STREAK_JOKER_MAX ].min : @m.streak_jokers)

    Reward.create!(user: @m.user, membership: @m, amount: diamonds, streak_week: streak,
                   reward_type: "diamonds", source: "streak", period:)
    offer_gift(streak) if milestone
    notify(streak, diamonds, milestone)
  end

  # Palier des 5 semaines : un cosmétique pas encore possédé, tiré au sort — comme la
  # récompense de ligue. Le tirage a lieu MAINTENANT (comme le contenu d'un coffre au drop),
  # seul le versement attend la réclamation. Inventaire déjà complet → 💎 de repli.
  def offer_gift(streak)
    cosmetic = Cosmetic.available.where.not(id: @m.user.user_cosmetics.select(:cosmetic_id)).order("RANDOM()").first

    if cosmetic
      Reward.create!(user: @m.user, membership: @m, cosmetic:, period:, streak_week: streak,
                     reward_type: "cosmetic", source: "streak_gift")
    else
      Reward.create!(user: @m.user, membership: @m, amount: GameRules::STREAK_GIFT_FALLBACK,
                     period:, streak_week: streak, reward_type: "diamonds", source: "streak_gift")
    end
  end

  def notify(streak, diamonds, milestone)
    extra = [ milestone ? "🎁 un cadeau surprise" : nil,
             milestone ? "🧊 +1 joker (#{@m.streak_jokers} en réserve)" : nil ].compact.join(" · ")
    Notification.create!(
      user: @m.user, game: @m.game, category: "streak", importance: "important",
      title: "🔥 #{streak} semaine#{"s" if streak > 1} de course d'affilée !",
      body: [ "#{diamonds} 💎 à réclamer sur ta piste", extra.presence ].compact.join(" · "),
      link: "/"
    )
  end
end
