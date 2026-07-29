class TrainingsController < ApplicationController
  before_action :require_authentication

  # Détail d'une sortie : tracé, photo, description, stats — ce qu'on récupère de Strava.
  def show
    training = Training.includes(:special_day, membership: [:team, :user]).find(params[:id])
    m = training.membership
    unless shares_game?(m.game_id)
      return redirect_to root_path, alert: "Cette sortie n'est pas dans une de tes parties."
    end

    render inertia: "Training", props: {
      training: TrainingPresenter.new(training).detail,
      author: MembershipPresenter.call(m)
    }
  end
end
