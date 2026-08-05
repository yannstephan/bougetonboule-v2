# Filet de sécurité : re-scanne les courses récentes au cas où un webhook aurait été manqué.
# Lancé une fois par jour par config/recurring.yml. Le temps réel passe par les webhooks.
#
# Deux sens :
#   - ce que Strava a et qu'on n'a pas (ou plus à jour) → (ré)import ;
#   - ce qu'on a et que Strava n'a plus → course supprimée, ou requalifiée en vélo : on la
#     retire du jeu (🍑 reprises, piège réarmé), au cas où le webhook « delete » se serait
#     perdu.
class StravaSyncJob < ApplicationJob
  queue_as :default

  FETCH_WINDOW = 3.days   # ce qu'on demande à Strava
  SWEEP_WINDOW = 2.days   # ce qu'on ose retirer (marge : jamais un bord de fenêtre)

  def perform
    User.where.not(strava_uid: nil).find_each do |user|
      token = StravaClient.valid_token_for(user)
      next unless token

      activities = StravaClient.new(token).recent_activities(after: FETCH_WINDOW.ago)
      next if activities.nil? # appel en échec : on ne conclut rien

      activities.select { |a| StravaClient.running?(a) }.each do |activity|
        StravaActivityImportJob.perform_later(owner_id: user.strava_uid, activity_id: activity["id"].to_s)
      end

      sweep_disappeared(user, activities)
    end
  end

  private

  # Courses encore comptées chez nous mais absentes de Strava (supprimées, ou changées en
  # une activité qui n'est plus une course à pied).
  def sweep_disappeared(user, activities)
    known = activities.map { |a| a["id"].to_s }

    Training.joins(:membership)
            .where(memberships: { user_id: user.id })
            .where(date: SWEEP_WINDOW.ago..)
            .where.not(status: "rejected")
            .where.not(strava_activity_id: [ nil, "" ])
            .find_each do |training|
      next if known.include?(training.strava_activity_id)

      RevokeTraining.call(training, reason: "Course introuvable sur Strava (supprimée ou modifiée).")
    end
  end
end
