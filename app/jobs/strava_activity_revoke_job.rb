# L'activité a été supprimée sur Strava : la course sort du jeu dans toutes les parties du
# joueur (🍑 reprises, score effacé, piège à loup réarmé — voir RevokeTraining).
class StravaActivityRevokeJob < ApplicationJob
  queue_as :default

  def perform(owner_id:, activity_id:)
    User.where(strava_uid: owner_id).find_each do |user|
      Training.joins(:membership).where(strava_activity_id: activity_id.to_s,
                                        memberships: { user_id: user.id }).find_each do |training|
        next if training.rejected?

        RevokeTraining.call(training, reason: "Course supprimée sur Strava.")
      end
    end
  end
end
