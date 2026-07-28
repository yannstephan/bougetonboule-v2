import { useState } from 'react'
import { router, usePage } from '@inertiajs/react'

// Carte coffre du Hub : un coffre scellé s'ouvre en deux temps (le 🎁 tremble, puis le
// serveur révèle les gains décidés au drop — flash.chest au rechargement Inertia).
const LABELS = { common: 'commun', rare: 'rare', epic: 'épique', legendary: 'légendaire' }

export default function ChestCard({ chest }) {
  const { flash } = usePage().props
  const [opening, setOpening] = useState(false)

  if (flash?.chest) {
    return (
      <div className={`chest-card revealed rar-${flash.chest.rarity}`}>
        <span className="chest-emoji">🎉</span>
        <div className="chest-text">
          <div className="chest-title">Coffre {LABELS[flash.chest.rarity]} ouvert !</div>
          <div className="chest-gains">{flash.chest.gains.join(' · ')}</div>
        </div>
      </div>
    )
  }
  if (!chest) return null

  const open = () => {
    if (opening) return
    setOpening(true)
    const reduced = window.matchMedia('(prefers-reduced-motion: reduce)').matches
    setTimeout(() => router.post(`/coffres/${chest.id}/ouvrir`, {}, { preserveScroll: true }),
               reduced ? 0 : 700)
  }

  return (
    <div className={`chest-card rar-${chest.rarity}`}>
      <span className={`chest-emoji ${opening ? 'shaking' : ''}`}>🎁</span>
      <div className="chest-text">
        <div className="chest-title">Un coffre {LABELS[chest.rarity]} t'attend !</div>
        <div className="chest-sub">Trouvé sur une de tes courses.</div>
      </div>
      <button className="chest-btn" onClick={open} disabled={opening}>{opening ? '…' : 'Ouvrir'}</button>
    </div>
  )
}
