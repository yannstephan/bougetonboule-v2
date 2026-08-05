import { useState } from 'react'
import { router, usePage } from '@inertiajs/react'

// Coffre du sac (/sac). Deux temps, de part et d'autre du rechargement Inertia :
// 1. clic sur « Ouvrir » → modal plein écran, le coffre tremble, puis POST (ChestCard) ;
// 2. le serveur répond avec flash.chest → la modal de révélation prend le relais
//    (couvercle qui s'ouvre, paillettes, gains qui sortent du coffre) — c'est ChestReveal,
//    monté une seule fois par page puisqu'on peut avoir plusieurs coffres en attente.
const LABELS = { common: 'commun', rare: 'rare', epic: 'épique', legendary: 'légendaire' }

const PARTICLES = Array.from({ length: 16 }, (_, i) => {
  const angle = (i / 16) * Math.PI * 2
  const dist = 90 + (i % 4) * 34
  return {
    dx: Math.round(Math.cos(angle) * dist),
    dy: Math.round(Math.sin(angle) * dist * 0.8) - 40,
    delay: (i % 5) * 0.08,
    glyph: i % 3 === 0 ? '✨' : i % 3 === 1 ? '⭐' : '●',
    color: ['var(--citron)', 'var(--peach)', 'var(--violet)', 'var(--mint)'][i % 4],
  }
})

function ChestSvg({ open, shaking }) {
  return (
    <svg viewBox="0 0 120 100" className={`chest-svg ${shaking ? 'shaking' : ''}`} aria-hidden>
      {/* couvercle (charnière à l'arrière : il bascule vers le haut à l'ouverture) */}
      <g className={`chest-lid ${open ? 'open' : ''}`}>
        <path d="M18 46 Q18 18 60 18 Q102 18 102 46 Z" fill="#b5722f" stroke="#8a5420" strokeWidth="3" />
        <rect x="52" y="30" width="16" height="16" rx="3" fill="#f2b100" />
      </g>
      {/* corps */}
      <rect x="18" y="46" width="84" height="42" rx="8" fill="#c98a45" stroke="#8a5420" strokeWidth="3" />
      <rect x="52" y="46" width="16" height="20" rx="3" fill="#f2b100" />
      <rect x="18" y="62" width="84" height="4" fill="#8a5420" opacity=".5" />
    </svg>
  )
}

// Phase révélation : la modal survit au rechargement grâce au flash. On mémorise le flash
// écarté (et pas un simple booléen) — sinon, le 2e coffre ouvert d'affilée s'ouvrirait muet.
export function ChestReveal() {
  const { flash } = usePage().props
  const [dismissed, setDismissed] = useState(null)

  if (flash?.chest && dismissed !== flash.chest) {
    const { rarity, gains } = flash.chest
    return (
      <div className="chest-modal" role="dialog" aria-label="Coffre ouvert">
        <div className="chest-stage">
          {PARTICLES.map((p, i) => (
            <span key={i} className="chest-particle" style={{
              '--dx': `${p.dx}px`, '--dy': `${p.dy}px`,
              animationDelay: `${p.delay}s`, color: p.color,
            }}>{p.glyph}</span>
          ))}
          <ChestSvg open />
          <div className="chest-gains-out">
            {gains.map((g, i) => (
              <div key={i} className={`chest-gain-chip rar-${rarity}`} style={{ animationDelay: `${0.45 + i * 0.3}s` }}>
                {g}
              </div>
            ))}
          </div>
          <div className="chest-reveal-title">Coffre {LABELS[rarity]} ouvert !</div>
          <button className="chest-btn" onClick={() => setDismissed(flash.chest)}>Récupérer 🎉</button>
        </div>
      </div>
    )
  }
  return null
}

export default function ChestCard({ chest }) {
  const [opening, setOpening] = useState(false)

  if (!chest) return null

  const open = () => {
    if (opening) return
    setOpening(true)
    const reduced = window.matchMedia('(prefers-reduced-motion: reduce)').matches
    setTimeout(() => router.post(`/coffres/${chest.id}/ouvrir`, {}, { preserveScroll: true }),
               reduced ? 0 : 900)
  }

  return (
    <>
      <div className={`chest-card rar-${chest.rarity}`}>
        <span className="chest-emoji">🎁</span>
        <div className="chest-text">
          <div className="chest-title">Un coffre {LABELS[chest.rarity]} t'attend !</div>
          <div className="chest-sub">Trouvé sur une de tes courses.</div>
        </div>
        <button className="chest-btn" onClick={open}>Ouvrir</button>
      </div>
      {opening && (
        <div className="chest-modal" role="dialog" aria-label="Ouverture du coffre">
          <div className="chest-stage">
            <ChestSvg shaking />
            <div className="chest-reveal-title">Ouverture…</div>
          </div>
        </div>
      )}
    </>
  )
}
