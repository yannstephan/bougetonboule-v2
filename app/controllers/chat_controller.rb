class ChatController < ApplicationController
  before_action :require_authentication

  def show
    m = current_membership
    return redirect_to root_path, alert: "Rejoins une partie pour discuter." unless m
    convs = [
      m.game.conversations.general.first,
      m.game.conversations.team_chats.find_by(team_id: m.team_id)
    ].compact
    # Le canal ouvert vient de l'URL (`?canal=team`), comme l'onglet du sac ou de la boutique :
    # c'est le seul moyen pour le serveur de savoir CE QU'ON LIT, et donc ce qu'il doit
    # marquer lu. Défaut : la conversation de la partie.
    active = convs.find { |c| c.kind == params[:canal] } || convs.first
    # ⚠️ Marquer AVANT de compter : le canal qu'on regarde doit afficher 0, pas son état
    # d'il y a une seconde. L'autre garde sa pastille — c'est tout l'intérêt.
    m.mark_conversation_read!(active)
    unread = m.unread_by_conversation

    props = {
      conversations: convs.map { |c| conv_json(c, m, unread[c.id].to_i) },
      active_kind: active&.kind,
      # Recherche de GIF : rechargement partiel Inertia (only: memes) plutôt qu'une API JSON
      # à part — la convention du projet. La source est choisie par Memes : Giphy si une clé
      # existe, sinon les catalogues sans clé.
      memes: Memes.search(params[:meme_q])
    }
    render inertia: "Chat", props:
  end

  private

  def conv_json(c, m, unread)
    {
      id: c.id, kind: c.kind, unread:,
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
