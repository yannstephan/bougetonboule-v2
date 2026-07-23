class MessagesController < ApplicationController
  before_action :require_authentication

  def create
    m = current_membership
    return redirect_to root_path unless m
    conv = Conversation.find(params[:conversation_id])
    authorized = conv.game_id == m.game_id && (conv.kind == "general" || conv.team_id == m.team_id)
    return head :forbidden unless authorized

    conv.messages.create!(membership: m, body: params[:body]) if params[:body].to_s.strip.present?
    redirect_to chat_path
  end
end
