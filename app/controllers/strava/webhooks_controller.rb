# Endpoint webhook Strava. GET = validation de l'abonnement, POST = réception d'events.
class Strava::WebhooksController < ApplicationController
  skip_forgery_protection

  # ⚠️ Pas de redirection vers l'hôte canonique ici : l'abonnement enregistré chez Strava
  # pointe sur l'apex et Strava NE SUIT PAS les redirections. Une 301 ferait échouer la
  # validation de l'abonnement (un GET) et perdre les événements de course.
  skip_before_action :redirect_to_canonical_host

  # Strava valide l'abonnement avec un GET contenant hub.challenge
  def verify
    if params["hub.verify_token"] == verify_token
      render json: { "hub.challenge" => params["hub.challenge"] }
    else
      head :forbidden
    end
  end

  # Réception d'un event : répondre vite (200), traiter en asynchrone.
  # - create / update : (ré)importer l'activité. Une course modifiée après coup est re-jugée
  #   — sport corrigé en vélo = elle sort du jeu, photo du tapis ajoutée = elle y entre.
  # - delete : la course est retirée (🍑 reprises, piège réarmé).
  def event
    if params[:object_type] == "activity"
      owner_id = params[:owner_id].to_s
      activity_id = params[:object_id].to_s

      case params[:aspect_type]
      when "create", "update" then StravaActivityImportJob.perform_later(owner_id:, activity_id:)
      when "delete"           then StravaActivityRevokeJob.perform_later(owner_id:, activity_id:)
      end
    end
    head :ok
  end

  private

  def verify_token
    Rails.application.credentials.dig(:strava, :verify_token) || ENV["STRAVA_VERIFY_TOKEN"] || "btb-verify"
  end
end
