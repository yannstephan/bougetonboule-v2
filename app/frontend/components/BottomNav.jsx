import { Link, usePage } from '@inertiajs/react'

// Les destinations du jeu. Le Chat n'est pas ici : il a rejoint les notifications dans le HUD —
// deux boutons de même nature (ce qu'on a reçu), et un onglet de moins en bas.
//
// L'onglet de la page courante s'allume : c'est LUI qui dit où l'on est, à la place du bandeau
// de titre qu'avait chaque écran. Déduit de l'URL et non d'une prop, pour qu'un écran ajouté
// plus tard ne puisse pas oublier de se déclarer.
export default function BottomNav() {
  const page = usePage()
  const { inventory_alert: bagAlert = 0 } = page.props
  const path = (page.url || '/').split('?')[0]
  // Les pages de détail (profil, sortie, admin) n'ont pas d'onglet : rien ne s'allume, et
  // c'est normal — on y arrive depuis un lien, pas depuis la barre.
  const cls = (p) => `n ${path === p || (p !== '/' && path.startsWith(p)) ? 'on' : ''}`

  return (
    <nav className="nav">
      <Link href="/" className={cls('/')}><span className="ic">🏠</span>Hub</Link>
      <Link href="/ligue" className={cls('/ligue')}><span className="ic">🏅</span>Ligue</Link>
      <Link href="/combat" className={`center ${path.startsWith('/combat') ? 'on' : ''}`}>⚔️</Link>
      <Link href="/sac" className={cls('/sac')}>
        {/* Pastille : quelque chose de neuf t'attend dans le sac (un coffre à ouvrir) */}
        <span className="ic nav-ic">🎒{bagAlert > 0 && <span className="nav-dot" aria-label="Nouveau dans ton sac" />}</span>Sac
      </Link>
      <Link href="/boutique" className={cls('/boutique')}><span className="ic">🛒</span>Boutique</Link>
    </nav>
  )
}
