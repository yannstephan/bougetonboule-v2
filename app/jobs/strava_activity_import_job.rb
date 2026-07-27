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
        status:             "pending",
        **strava_details(activity)
      )
      TrainingScorer.call(training)
      training.save!

      # Confirmation à soi-même (secondaire : pas urgent, le solde 🍑 se met à jour tout seul).
      Notification.create!(
        user:, game: membership.game, category: "training_verified",
        title: "Course importée",
        body: "#{training.distance_km.round(1)} km · +#{training.score.to_i} pêches (en attente de validation)"
      )
      broadcast_run(membership, training)
    end
  end

  # Feed d'activité : "X a couru N km", vu par les autres joueurs de la partie (secondaire).
  def broadcast_run(membership, training)
    others = membership.game.memberships.includes(:user).where.not(id: membership.id).map(&:user)
    Notification.broadcast(others, game: membership.game, category: "training_verified",
                           title: "🏃 Nouvelle course",
                           body: "#{membership.display_name} a couru #{training.distance_km.round(1)} km.")
  end

  # Champs détaillés Strava, à stocker pour la page d'une sortie.
  def strava_details(activity)
    {
      title:          activity["name"],
      description:     activity["description"],
      moving_time:    activity["moving_time"],
      elapsed_time:   activity["elapsed_time"],
      elevation_gain: activity["total_elevation_gain"],
      route_points:   Polyline.decode(activity.dig("map", "summary_polyline")),
      photo_url:      activity.dig("photos", "primary", "urls")&.values&.last
    }
  end
end
