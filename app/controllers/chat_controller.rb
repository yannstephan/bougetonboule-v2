class ChatController < ApplicationController
  before_action :require_authentication
  before_action -> { require_membership("discuter") }

  def show
    m = current_membership
    props = { conversations: m.conversations.map { |c| conv_json(c, m) } }
    # Ouvrir le chat vaut lecture : la pastille de l'onglet retombe à zéro (calculée après, dans le
    # partage Inertia, donc déjà 0 sur cette page).
    m.mark_conversations_read!
    render inertia: "Chat", props:
  end

  private

  def conv_json(conversation, me)
    {
      id: conversation.id, kind: conversation.kind,
      label: conversation.kind == "general" ? "Partie" : "Mon équipe",
      messages: messages_json(conversation, me)
    }
  end

  def messages_json(conversation, me)
    scope = conversation.messages.chronological.includes(membership: [:team, :user])
    scope.last(60).map do |msg|
      { id: msg.id, body: msg.body,
        author: MembershipPresenter.call(msg.membership),
        mine: msg.membership_id == me.id,
        at: msg.created_at.strftime("%H:%M"),
        on: msg.created_at.strftime("%d/%m/%Y"),
        day_label: HumanDates.day_label(msg.created_at) }
    end
  end
end
