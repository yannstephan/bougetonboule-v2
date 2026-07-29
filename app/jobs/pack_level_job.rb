# Jauge de meute — tourne le lundi matin (config/recurring.yml) et juge la semaine ÉCOULÉE :
# si au moins 5 coéquipiers ont chacun couru 10 km (courses qui comptent), l'équipe gagne un
# palier permanent de +10 % sur ses attaques et ses soins (plafond ×2, voir GameRules).
# C'est le seul « booster » du jeu : gagné en courant à plusieurs, jamais acheté.
class PackLevelJob < ApplicationJob
  queue_as :default

  def perform(week_start: Date.current.beginning_of_week - 7.days)
    window = week_start.beginning_of_day..(week_start + 6.days).end_of_day

    Game.where(status: "active").find_each do |game|
      game.teams.find_each { |team| judge(team, window) }
    end
  end

  private

  def judge(team, window)
    return if team.pack_level >= GameRules::PACK_MAX_LEVEL

    runners = qualified_runners(team, window)
    return if runners < GameRules::PACK_RUNNERS_NEEDED

    team.increment!(:pack_level)
    announce(team, runners)
  end

  # Nombre de coéquipiers ayant couru au moins PACK_WEEKLY_KM sur la fenêtre.
  def qualified_runners(team, window)
    Training.scoring
            .where(membership: team.memberships, date: window)
            .group(:membership_id)
            .sum(:distance_meters)
            .count { |_id, meters| meters >= GameRules::PACK_WEEKLY_KM * 1000 }
  end

  def announce(team, runners)
    Notification.broadcast(team.users,
                           game: team.game, importance: "important", category: "pack",
                           title: "🐾 Meute niveau #{team.pack_level} !",
                           body: "#{runners} d'entre vous ont couru #{GameRules::PACK_WEEKLY_KM} km cette semaine : " \
                                 "attaques et soins +#{team.pack_percent} % pour toujours.")
    return unless team.opponent

    Notification.broadcast(team.opponent.users,
                           game: team.game, category: "pack",
                           title: "🐾 La meute adverse grandit",
                           body: "#{team.name} passe meute niveau #{team.pack_level} (+#{team.pack_percent} %).")
  end
end
