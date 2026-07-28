class ProfilesController < ApplicationController
  before_action :require_authentication

  # Profil d'un joueur = une participation (Membership) : ses sorties dans une partie donnée.
  def show
    membership = Membership.includes(:user, :team, trainings: :special_day).find(params[:id])
    unless shares_game?(membership.game_id)
      return redirect_to root_path, alert: "Ce profil n'est pas dans une de tes parties."
    end

    render inertia: "Profile", props: props(membership)
  end

  private

  def props(m)
    trainings = m.trainings.recent
    scoring = trainings.select { |t| t.status.in?(%w[verified protected]) }
    {
      game: { id: m.game.id, name: m.game.name },
      player: {
        id: m.id, name: m.display_name, fruit_name: m.fruit_name,
        avatar: AvatarPresenter.new(m.user, membership: m).as_json,
        team: { name: m.team.name, color: m.team.color, family: m.team.fruit_family },
        is_me: m.user_id == current_user.id
      },
      # Pas de solde de 🍑 ici : la réserve d'un joueur ne se voit que sur sa propre page d'accueil.
      stats: {
        total_km: (scoring.sum(&:distance_meters) / 1000.0).round(1),
        month_score: month_score(m),
        trainings_count: scoring.size
      },
      trainings: trainings.map { |t| TrainingPresenter.new(t).summary }
    }
  end

  def month_score(m)
    LeagueStandings.month(m.game).row_for(m)&.score.to_f.round(1)
  end
end
