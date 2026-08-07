class ChatController < ApplicationController
  before_action :require_authentication

  # Le fil ne part jamais en entier : on sert la DERNIÈRE page et on remonte à la demande.
  # Une conversation de saison finit à plusieurs milliers de messages, et le chat se recharge
  # toutes les 8 s — tout envoyer, c'est payer l'historique complet huit fois par minute.
  PAGE = 30

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
      conversations: convs.map { |c| conv_json(c, m, unread[c.id].to_i, open: c == active) },
      active_kind: active&.kind,
      # ⚠️ Ces deux-là sont `optional` : Inertia ne les évalue QUE si le front les nomme dans
      # un `only:`. Le bloc n'est donc pas exécuté au chargement de la page, ni aux 8 s de
      # sondage. Sans ça, `Memes.search` partait chez Giphy à chaque tour de sondage — huit
      # appels par minute et par onglet ouvert, pour un panneau que personne n'a ouvert.
      # C'est la vraie économie de cet écran, bien avant la pagination.
      #
      # La page d'avant : réclamée par `only: ['older']` avec `?avant=<id>`.
      older: InertiaRails.optional { older_json(active, params[:avant]) },
      # Recherche de GIF : réclamée par `only: ['memes']` avec `?meme_q=`. Rechargement partiel
      # plutôt qu'une API JSON à part — la convention du projet. La source est choisie par
      # Memes : Giphy si une clé existe, sinon les catalogues sans clé.
      memes: InertiaRails.optional { Memes.search(params[:meme_q]) }
    }
    render inertia: "Chat", props:
  end

  private

  # ⚠️ Seule la conversation OUVERTE porte ses messages. L'autre n'est qu'un onglet et une
  # pastille — le front ne rend jamais son fil, et changer d'onglet est une visite qui la
  # servira à ce moment-là. C'est la moitié du poids de la page, gagnée sans rien perdre.
  def conv_json(c, m, unread, open:)
    base = { id: c.id, kind: c.kind, unread:,
             label: c.kind == "general" ? "Partie" : "Mon équipe" }
    return base.merge(has_more: false, messages: []) unless open

    base.merge(page(c.messages, m))
  end

  def older_json(conversation, before_id)
    return nil if conversation.nil? || before_id.blank?

    # Curseur (created_at, id) et non l'id seul : le seed pose des `created_at` à la main, deux
    # messages peuvent partager la seconde. C'est le même couple que l'ordre de `chronological`,
    # sinon une page sauterait ou répéterait un message à sa frontière.
    pivot = conversation.messages.find_by(id: before_id)
    return nil unless pivot

    scope = conversation.messages.where(
      "messages.created_at < :t OR (messages.created_at = :t AND messages.id < :i)",
      t: pivot.created_at, i: pivot.id
    )
    page(scope, current_membership).merge(before: pivot.id)
  end

  # Une page = les PAGE plus récents du périmètre demandé. On en tire un de plus que nécessaire :
  # c'est ce qui répond « y en a-t-il encore avant ? » sans un second COUNT.
  def page(scope, me)
    rows = scope.chronological.includes(membership: [ :team, :user ]).last(PAGE + 1)
    { has_more: rows.size > PAGE, messages: rows.last(PAGE).map { message_json(_1, me) } }
  end

  def message_json(msg, me)
    author = msg.membership
    # `ts` n'est pas de l'affichage : c'est la CLÉ DE TRI du front, qui doit recoller une page
    # ancienne devant un fil déjà chargé. `on`/`at` sont des libellés à la minute — deux
    # messages de la même minute s'y égalisent, et l'ordre du serveur serait perdu.
    { id: msg.id, ts: msg.created_at.to_i, body: msg.body,
      meme_url: msg.meme_url, meme_title: msg.meme_title,
      membership_id: author.id,
      author: author.display_name,
      avatar: AvatarPresenter.new(author.user, membership: author).as_json,
      team: { name: author.team.name, color: author.team.color },
      mine: msg.membership_id == me.id,
      at: msg.created_at.strftime("%H:%M"),
      on: msg.created_at.strftime("%d/%m/%Y"),
      day_label: day_label(msg.created_at) }
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
