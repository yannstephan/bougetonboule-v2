class ChatController < ApplicationController
  before_action :require_authentication

  def show
    m = current_membership
    return redirect_to root_path, alert: "Rejoins une partie pour discuter." unless m
    convs = [
      m.game.conversations.general.first,
      m.game.conversations.team_chats.find_by(team_id: m.team_id)
    ].compact
    render inertia: "Chat", props: { conversations: convs.map { |c| conv_json(c, m) } }
  end

  private

  def conv_json(c, m)
    {
      id: c.id, kind: c.kind,
      label: c.kind == "general" ? "Partie" : "Mon équipe",
      messages: c.messages.chronological.includes(membership: :user).last(60).map do |msg|
        { id: msg.id, body: msg.body, author: msg.membership.user.firstname,
          mine: msg.membership_id == m.id, at: msg.created_at.strftime("%H:%M") }
      end
    }
  end
end
