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

  # Prévient les autres participants. Un message d'équipe est important (poussé) ; le chat
  # général reste secondaire (listé, pas de push) pour ne pas spammer toute la partie.
  def notify_participants(conv, sender, message)
    scope = conv.kind == "team" ? conv.team.memberships : conv.game.memberships
    recipients = scope.includes(:user).where.not(id: sender.id).map(&:user)
    label = conv.kind == "team" ? "équipe" : "partie"

    Notification.broadcast(recipients, game: conv.game, category: "message",
                           importance: conv.kind == "team" ? "important" : "secondary",
                           title: "💬 #{sender.display_name} · #{label}",
                           body: message.body.truncate(90))
  end
end
