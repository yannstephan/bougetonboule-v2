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
    verified = trainings.select { |t| t.status == "verified" }
    {
      game: { id: m.game.id, name: m.game.name },
      player: {
        id: m.id, name: m.display_name, fruit_name: m.fruit_name,
        avatar: AvatarPresenter.new(m.user, membership: m).as_json,
        team: { name: m.team.name, color: m.team.color, family: m.team.fruit_family },
        is_me: m.user_id == current_user.id
      },
      stats: {
        balls: m.balls,
        total_km: (verified.sum(&:distance_meters) / 1000.0).round(1),
        month_score: month_score(m),
        trainings_count: verified.size
      },
      trainings: trainings.map { |t| TrainingPresenter.new(t).summary }
    }
  end

  def month_score(m)
    LeagueStandings.month(m.game).row_for(m)&.score.to_f.round(1)
  end
end
