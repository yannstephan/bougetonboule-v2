# Importe une activité Strava précise dans toutes les parties actives du joueur.
class StravaActivityImportJob < ApplicationJob
  queue_as :default

  def perform(owner_id:, activity_id:)
    User.where(strava_uid: owner_id).find_each do |user|
      token = StravaClient.valid_token_for(user)
      next unless token

      activity = StravaClient.new(token).activity(activity_id)
      next unless activity && activity["type"] == "Run"

      import_for(user, activity)
    end
  end

  private

  def import_for(user, activity)
    strava_id = activity["id"].to_s

    user.memberships.joins(:game).where(games: { status: "active" }).find_each do |membership|
      next if membership.trainings.exists?(strava_activity_id: strava_id)

      training = membership.trainings.build(
        strava_activity_id: strava_id,
        date:               Time.zone.parse(activity["start_date"].to_s),
        distance_meters:    activity["distance"].to_i,
        status:             "pending"
      )
      TrainingScorer.call(training)
      training.save!

      Notification.create!(
        user:, game: membership.game, category: "training_verified",
        title: "Course importée",
        body: "#{training.distance_km.round(1)} km · +#{training.score.to_i} pêches (en attente de validation)"
      )
    end
  end
end
