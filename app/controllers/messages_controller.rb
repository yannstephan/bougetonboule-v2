class MessagesController < ApplicationController
  before_action :require_authentication

  def create
    m = current_membership
    return redirect_to root_path unless m
    conv = Conversation.find(params[:conversation_id])
    authorized = conv.game_id == m.game_id && (conv.kind == "general" || conv.team_id == m.team_id)
    return head :forbidden unless authorized

    if params[:body].to_s.strip.present?
      message = conv.messages.create!(membership: m, body: params[:body])
      notify_participants(conv, m, message)
    end
    redirect_to chat_path
  end

  private

  # Seul le chat d'équipe déclenche une notification (importante, poussée). Le chat général
  # ne notifie personne : on le suit en ouvrant le chat, pas dans la liste des notifications.
  def notify_participants(conv, sender, message)
    return unless conv.kind == "team"

    recipients = conv.team.memberships.includes(:user).where.not(id: sender.id).map(&:user)
    Notification.broadcast(recipients, game: conv.game, category: "message", importance: "important",
                           title: "💬 #{sender.display_name} · équipe",
                           body: message.body.truncate(90))
  end
end
