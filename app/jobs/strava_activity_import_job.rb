# Importe une activité Strava précise dans toutes les parties actives du joueur.
# Le jeu (scoring, pièges, 🍑, coffre, notifications) se déroule dans RecordTraining ;
# ce job ne fait que parler à Strava.
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

      RecordTraining.call(membership.trainings.build(
        strava_activity_id: strava_id,
        date:               Time.zone.parse(activity["start_date"].to_s),
        distance_meters:    activity["distance"].to_i,
        status:             "verified",
        **strava_details(activity)
      ))
    end
  end

  # Champs détaillés Strava, à stocker pour la page d'une sortie.
  def strava_details(activity)
    {
      title:          activity["name"],
      description:    activity["description"],
      moving_time:    activity["moving_time"],
      elapsed_time:   activity["elapsed_time"],
      elevation_gain: activity["total_elevation_gain"],
      route_points:   Polyline.decode(activity.dig("map", "summary_polyline")),
      photo_url:      activity.dig("photos", "primary", "urls")&.values&.last
    }
  end
end
