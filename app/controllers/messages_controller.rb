class MessagesController < ApplicationController
  before_action :require_authentication

  def create
    m = current_membership
    return redirect_to root_path unless m
    conv = Conversation.find(params[:conversation_id])
    authorized = conv.game_id == m.game_id && (conv.kind == "general" || conv.team_id == m.team_id)
    return head :forbidden unless authorized

    message = conv.messages.new(membership: m, body: params[:body].to_s.strip.presence,
                                **meme_attributes)
    notify_participants(conv, m, message) if message.save
    redirect_to chat_path
  end

  private

  # Un meme n'est accepté que s'il vient bien du catalogue : sans cette vérification,
  # `meme_url` serait un champ « affiche l'image de ton choix » posté à la main.
  def meme_attributes
    url = params[:meme_url].to_s
    return {} unless url.present? && Memes.allowed?(url)

    { meme_url: url, meme_title: params[:meme_title].to_s.truncate(120).presence }
  end

  # Seul le chat d'équipe déclenche une notification (importante, poussée). Le chat général
  # ne notifie personne : on le suit en ouvrant le chat, pas dans la liste des notifications.
  def notify_participants(conv, sender, message)
    return unless conv.kind == "team"

    recipients = conv.team.memberships.includes(:user).where.not(id: sender.id).map(&:user)
    Notification.broadcast(recipients, game: conv.game, category: "message", importance: "important",
                           title: "💬 #{sender.display_name} · équipe",
                           body: message.preview)
  end
end
