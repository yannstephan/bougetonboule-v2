class ChatController < ApplicationController
  before_action :require_authentication

  def show
    m = current_membership
    return redirect_to root_path, alert: "Rejoins une partie pour discuter." unless m
    convs = [
      m.game.conversations.general.first,
      m.game.conversations.team_chats.find_by(team_id: m.team_id)
    ].compact
    props = {
      conversations: convs.map { |c| conv_json(c, m) },
      # Recherche de memes : rechargement partiel Inertia (only: memes) plutôt qu'une
      # API JSON à part — la convention du projet. La source est choisie par Memes :
      # Giphy si une clé existe, sinon Imgflip qui n'en demande aucune.
      memes: Memes.search(params[:meme_q])
    }
    # Ouvrir le chat vaut lecture : la pastille de l'onglet retombe à zéro (calculée après, dans le
    # partage Inertia, donc déjà 0 sur cette page).
    m.mark_conversations_read!
    render inertia: "Chat", props:
  end

  private

  def conv_json(c, m)
    {
      id: c.id, kind: c.kind,
      label: c.kind == "general" ? "Partie" : "Mon équipe",
      messages: messages_json(c, m)
    }
  end

  def messages_json(conversation, me)
    scope = conversation.messages.chronological
                        .includes(membership: [ :team, :user ])
    scope.last(60).map do |msg|
      author = msg.membership
      { id: msg.id, body: msg.body, meme_url: msg.meme_url, meme_title: msg.meme_title,
        membership_id: author.id,
        author: author.display_name,
        avatar: AvatarPresenter.new(author.user, membership: author).as_json,
        team: { name: author.team.name, color: author.team.color },
        mine: msg.membership_id == me.id,
        at: msg.created_at.strftime("%H:%M"),
        on: msg.created_at.strftime("%d/%m/%Y"),
        day_label: day_label(msg.created_at) }
    end
  end

  # Sépare visuellement les journées dans le fil.
  def day_label(time)
    case time.to_date
    when Date.current      then "Aujourd'hui"
    when Date.yesterday    then "Hier"
    else time.strftime("%d/%m/%Y")
    end
  end
end
