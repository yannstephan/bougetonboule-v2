# Décerne la récompense du 1er du classement mensuel, pour toutes les parties actives.
#
# Tourne le 1er de chaque mois (voir config/recurring.yml) et juge le mois ÉCOULÉ.
# Le classement du nouveau mois repart de zéro tout seul : il est dérivé des courses
# du mois en cours, il n'y a donc rien à remettre à zéro en base.
class LeagueMonthlyRewardJob < ApplicationJob
  queue_as :default

  def perform(month = nil)
    month = month ? month.to_date : Date.current.prev_month

    Game.where(status: "active").find_each do |game|
      result = AwardMonthlyLeague.call(game, month)
      Rails.logger.info("[Ligue] #{game.name} #{month.strftime('%Y-%m')} : " \
                        "#{result.awarded ? 'récompense décernée' : result.reason}")
    end
  end
end
