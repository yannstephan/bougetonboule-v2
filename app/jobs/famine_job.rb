# Monstre affamé + fin de saison — tourne tous les jours (config/recurring.yml).
#
# Famine : une équipe sans aucune course depuis 72h voit son monstre perdre 50 PV par jour
# de jeûne. Plancher à 5 % des PV max : la famine ne tue jamais, le coup final reste aux
# joueurs. Le Hub affiche déjà un avertissement 🍽️ dès 48h (TeamEffectsPresenter).
#
# Fin de saison : à la date de fin de la partie (ends_at), l'équipe dont le monstre a le
# plus haut % de PV gagne (FinishGame.by_hp — égalité possible).
class FamineJob < ApplicationJob
  queue_as :default

  def perform
    Game.where(status: "active").find_each do |game|
      if game.ends_at&.past?
        FinishGame.by_hp(game)
        next
      end

      game.teams.includes(:monster).find_each { |team| starve(team) }
    end
  end

  private

  def starve(team)
    monster = team.monster
    return unless monster&.alive?

    last_run = team.last_run_at
    return if last_run.present? && last_run > GameRules::FAMINE_AFTER.ago

    floor = (monster.max_hp * GameRules::FAMINE_FLOOR_RATIO).round
    return if monster.hp <= floor

    lost = [GameRules::FAMINE_HP_PER_DAY, monster.hp - floor].min
    monster.update!(hp: monster.hp - lost)
    monster.refresh_state!
    announce(team, monster, lost)
  end

  def announce(team, monster, lost)
    Notification.broadcast(team.memberships.includes(:user).map(&:user),
                           game: team.game, importance: "important", category: "famine",
                           title: "🍽️ #{monster.name} a faim !",
                           body: "Personne n'a couru depuis 3 jours : #{monster.name} perd #{lost} PV. " \
                                 "Nourris-le en allant courir !")
    return unless team.opponent

    Notification.broadcast(team.opponent.memberships.includes(:user).map(&:user),
                           game: team.game, category: "famine",
                           title: "🍽️ Monstre affamé",
                           body: "#{monster.name} dépérit (−#{lost} PV) : #{team.name} ne court plus.")
  end
end
