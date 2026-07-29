# Endpoint webhook Strava. GET = validation de l'abonnement, POST = réception d'events.
class Strava::WebhooksController < ApplicationController
  skip_forgery_protection

  # Strava valide l'abonnement avec un GET contenant hub.challenge
  def verify
    if params["hub.verify_token"] == StravaClient.verify_token
      render json: { "hub.challenge" => params["hub.challenge"] }
    else
      head :forbidden
    end
  end

  # Réception d'un event : répondre vite (200), traiter en asynchrone
  def event
    if params[:object_type] == "activity" && params[:aspect_type] == "create"
      StravaActivityImportJob.perform_later(
        owner_id:    params[:owner_id].to_s,
        activity_id: params[:object_id].to_s
      )
    end
    head :ok
  end
end
