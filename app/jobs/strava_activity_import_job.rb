# Importe (ou remet à jour) une activité Strava précise dans toutes les parties actives du
# joueur. Sert aux trois déclencheurs : webhook « create », webhook « update » (l'activité a
# été modifiée sur Strava — sport corrigé, photo ajoutée…) et réconciliation quotidienne.
# Le jugement (anti-triche) et le scoring vivent dans ImportTraining / TrainingPolicy.
class StravaActivityImportJob < ApplicationJob
  queue_as :default

  def perform(owner_id:, activity_id:)
    User.where(strava_uid: owner_id).find_each do |user|
      token = StravaClient.valid_token_for(user)
      next unless token

      activity = StravaClient.new(token).activity(activity_id)
      next unless activity && activity["id"]

      user.memberships.joins(:game).where(games: { status: "active" }).find_each do |membership|
        ImportTraining.call(membership, activity)
      end
    end
  end
end
