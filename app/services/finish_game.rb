# Termine une partie et annonce le résultat à tous les joueurs.
# Deux chemins : un monstre meurt (winner = l'équipe attaquante), ou la date de fin
# est atteinte (winner = l'équipe dont le monstre a le plus haut % de PV ; nil = égalité).
class FinishGame
  def self.call(game, winner: nil) = new(game, winner:).call

  def initialize(game, winner:)
    @game = game
    @winner = winner
  end

  def call
    return if @game.finished?

    @game.update!(status: "finished", winner_team_id: @winner&.id)
    announce
    @game
  end

  # À la date de fin : départage au pourcentage de PV restants.
  def self.by_hp(game)
    teams = game.teams.includes(:monster).to_a
    best, second = teams.sort_by { |t| -(t.monster&.hp_ratio || 0) }
    winner = best && second && best.monster&.hp_ratio == second.monster&.hp_ratio ? nil : best
    call(game, winner:)
  end

  private

  def announce
    body =
      if @winner
        "Victoire des #{@winner.name} 🏆 Merci d'avoir couru — rendez-vous à la prochaine saison !"
      else
        "Égalité parfaite entre les deux clans 🤝 Merci d'avoir couru !"
      end
    Notification.broadcast(@game.memberships.includes(:user).map(&:user),
                           game: @game, importance: "important", category: "game_over",
                           title: "🏁 La partie est terminée", body:)
  end
end
