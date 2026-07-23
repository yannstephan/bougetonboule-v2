# Filet de sécurité : re-scanne les courses récentes au cas où un webhook aurait été manqué.
# Lancé une fois par jour par config/recurring.yml. Le temps réel passe par les webhooks.
class StravaSyncJob < ApplicationJob
  queue_as :default

  def perform
    User.where.not(strava_uid: nil).find_each do |user|
      token = StravaClient.valid_token_for(user)
      next unless token

      StravaClient.new(token).recent_runs(after: 2.days.ago).each do |activity|
        StravaActivityImportJob.perform_later(owner_id: user.strava_uid, activity_id: activity["id"].to_s)
      end
    end
  end
end
