# Sync horaire : importe les courses Strava des joueurs des parties actives,
# crée les Training manquants et les score. Lancé par config/recurring.yml.
class StravaSyncJob < ApplicationJob
  queue_as :default

  def perform
    Game.where(status: "active").find_each do |game|
      game.memberships.includes(:user).find_each { |m| sync_membership(m) }
    end
  end

  private

  def sync_membership(membership)
    user = membership.user
    return unless user.strava_connected?

    StravaClient.new(user.strava_token).recent_runs.each do |activity|
      import_activity(membership, activity)
    end
  end

  def import_activity(membership, activity)
    strava_id = activity["id"].to_s
    return if Training.exists?(strava_activity_id: strava_id)

    training = membership.trainings.build(
      strava_activity_id: strava_id,
      date: Time.zone.parse(activity["start_date"].to_s),
      distance_meters: activity["distance"].to_i,
      status: "pending"
    )
    TrainingScorer.call(training)
    training.save!
    notify(training)
  end

  def notify(training)
    Notification.create!(
      user: training.membership.user,
      game: training.membership.game,
      category: "training_verified",
      title: "Course importée",
      body: "#{training.distance_km.round(1)} km · +#{training.score.to_i} pêches (en attente de validation)"
    )
  end
end
