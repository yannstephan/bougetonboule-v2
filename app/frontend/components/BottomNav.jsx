import { Link, usePage } from '@inertiajs/react'

// Les destinations du jeu. Le Chat n'est plus ici : il a rejoint les notifications dans le HUD
// du Hub — deux boutons de même nature (ce qu'on a reçu), et un onglet de moins en bas.
export default function BottomNav({ active }) {
  const { inventory_alert: bagAlert = 0 } = usePage().props
  const cls = (k) => `n ${active === k ? 'on' : ''}`
  return (
    <nav className="nav">
      <Link href="/" className={cls('hub')}><span className="ic">🏠</span>Hub</Link>
      <Link href="/ligue" className={cls('ligue')}><span className="ic">🏅</span>Ligue</Link>
      <Link href="/combat" className="center">⚔️</Link>
      <Link href="/sac" className={cls('bag')}>
        {/* Pastille : quelque chose de neuf t'attend dans le sac (un coffre à ouvrir) */}
        <span className="ic nav-ic">🎒{bagAlert > 0 && <span className="nav-dot" aria-label="Nouveau dans ton sac" />}</span>Sac
      </Link>
      <Link href="/boutique" className={cls('shop')}><span className="ic">🛒</span>Boutique</Link>
    </nav>
  )
}
