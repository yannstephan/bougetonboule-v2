import { Link } from '@inertiajs/react'

export default function BottomNav({ active }) {
  const cls = (k) => `n ${active === k ? 'on' : ''}`
  return (
    <nav className="nav">
      <Link href="/" className={cls('hub')}><span className="ic">🏠</span>Hub</Link>
      <Link href="/chat" className={cls('chat')}><span className="ic">💬</span>Chat</Link>
      <Link href="/combat" className="center">⚔️</Link>
      <Link href="/ligue" className={cls('ligue')}><span className="ic">🏅</span>Ligue</Link>
      <Link href="/boutique" className={cls('shop')}><span className="ic">🛒</span>Boutique</Link>
    </nav>
  )
}
