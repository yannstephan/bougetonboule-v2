import { Link, usePage } from '@inertiajs/react'
import PlayerAvatar from './PlayerAvatar'

// Le bandeau du haut, présent sur TOUTES les pages (avec le footer) : qui je suis, ce que je
// possède, et les deux boîtes de réception — 💬 le chat et 🔔 les notifications.
// Il ne prend aucune prop : tout vient de `inertia_share`, donc l'ajouter à un écran ne demande
// rien à son contrôleur. Collé en haut (`.hud`), il reste visible quand on fait défiler.
//
// C'est aussi lui qui dit OÙ L'ON EST : l'icône de la page courante s'allume. Les pages n'ont
// donc plus de bandeau de titre — l'information est portée par le logo, pas par une ligne de
// texte qui mangeait de la hauteur sur chaque écran. L'état actif est déduit de l'URL et non
// d'une prop : impossible d'oublier de la passer en ajoutant un écran.
export default function Hud() {
  const page = usePage()
  const { auth, balls = 0, chat_unread: chatUnread = 0 } = page.props
  const user = auth?.user
  const unread = user?.unread_count || 0
  const path = (page.url || '/').split('?')[0]
  const on = (p) => (path === p ? ' on' : '')

  return (
    <header className="hud">
      <Link href="/avatar" className={`hud-avatar${on('/avatar')}`} title="Mon avatar et mon compte">
        <PlayerAvatar avatar={user?.avatar} size={38} />
      </Link>
      <span className="curr">🍑 {balls}</span>
      <span className="curr">💎 {user?.diamonds ?? 0}</span>
      <Link href="/faq" className={`bell${on('/faq')}`} title="Règles du jeu">📖</Link>
      <Link href="/chat" className={`bell bell-badge${on('/chat')}`} title="Chat">
        💬{chatUnread > 0 && <span className="b">{chatUnread > 9 ? '9+' : chatUnread}</span>}
      </Link>
      <Link href="/notifications" className={`bell bell-badge${on('/notifications')}`} title="Notifications">
        🔔{unread > 0 && <span className="b">{unread > 99 ? '99+' : unread}</span>}
      </Link>
    </header>
  )
}
