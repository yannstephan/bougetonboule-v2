import { useMemo, useState } from 'react'
import { router, usePage } from '@inertiajs/react'
import { rarityLabel, rarityWord } from '../lib/rarity'
import { CosmeticIcon } from './cosmeticArt'

// Coffre du sac (/sac). Trois temps, de part et d'autre du rechargement Inertia :
// 1. clic sur « Ouvrir » → modal plein écran, le coffre s'agite de plus en plus fort et
//    fait trembler l'écran (ChestCard) ;
// 2. POST ; le serveur répond avec flash.chest ;
// 3. la révélation prend le relais (ChestReveal) : flash, roue de rayons, couvercle qui
//    claque, colonne de lumière, pluie de pièces, et le butin qui SORT du coffre.
// ChestReveal est monté UNE SEULE fois par page (on peut avoir plusieurs coffres en attente).
//
// ⚠️ La rareté dont il est question ici est celle de `Chest#loot_rarity` — le PLUS BEAU
// contenu du coffre, pas son palier : un coffre commun qui cache un légendaire s'ouvre en or,
// avec la fanfare et la durée qui vont avec. C'est la seule que le front reçoive.
// ⚠️ La carte scellée ne dit RIEN de la rareté : elle n'existe qu'à partir du clic sur
// « Ouvrir ». On la découvre à la couleur du halo pendant que le coffre s'agite, une seconde
// avant qu'elle n'éclate à la révélation — c'est là toute la tension du geste. Une pastille
// sur la carte aurait vendu la mèche des jours à l'avance.
// À partir de là, la rareté ne se lit pas, elle se voit : la modale porte `rar-<rareté>` et
// tout ce qu'il y a dedans est peint dans --rar (voir « Ouverture d'un coffre » dans le CSS).

// Combien de fanfare selon la rareté, et combien de TEMPS. La COULEUR vient de --rar ; ici
// on règle la QUANTITÉ et la DURÉE — un commun ne doit pas se jouer comme un légendaire,
// sinon le légendaire ne vaut plus rien.
//   burst / coins : nombre d'éclats et de pièces
//   light  → --fanfare : intensité des lumières
//   rattle → --rattle  : combien de temps le coffre s'agite avant de céder. Un légendaire
//            se fait attendre trois fois plus longtemps qu'un commun. C'est le MÊME nombre
//            qui minute le POST : la modale ne peut pas se désynchroniser de son animation.
//            Il donne aussi --shivers, le NOMBRE de secousses (la fréquence, elle, est fixe
//            — voir la note sur chest-shiver dans le CSS).
//   k      → --k       : facteur de temps de la révélation. Chaque durée du CSS est un
//            calc(… * var(--k)), donc tout s'étire d'un coup, sans rien réaccorder.
//            ⚠️ --k étire l'ATMOSPHÈRE (rayons, colonne, onde) et l'attente entre deux
//            gains. Les GESTES — le couvercle qui claque, le coffre qui encaisse, le butin
//            qui vole — suivent --k2, deux fois moins ample : un geste trop lent ne se lit
//            pas comme de la solennité, il se lit comme une appli qui rame. Et le flash,
//            lui, ne s'étire pas du tout (voir le CSS).
// Une seule table, lue par les deux modales (l'agitation et la révélation).
// L'écart entre les paliers est VOLONTAIREMENT brutal : un commun expédié en moins de deux
// secondes est ce qui rend les sept secondes d'un légendaire supportables — et désirables.
// C'est le contraste qui porte la récompense, pas la durée absolue.
const FANFARE = {
  common: { burst: 8, coins: 4, light: 0.4, rattle: 600, k: 0.8 },
  rare: { burst: 18, coins: 14, light: 0.7, rattle: 1200, k: 1.2 },
  epic: { burst: 34, coins: 30, light: 0.92, rattle: 2100, k: 1.8 },
  legendary: { burst: 60, coins: 56, light: 1.15, rattle: 3400, k: 2.6 },
}
const fanfareOf = (r) => FANFARE[r] || FANFARE.rare
// Les trois réglages que le CSS lit, posés en ligne sur la modale.
const SHIVER_MS = 160 // doit rester égal à la durée de @keyframes chest-shiver
const fxStyle = (f) => ({
  '--fanfare': f.light, '--rattle': `${f.rattle}ms`, '--k': f.k,
  '--k2': 1 + (f.k - 1) * 0.4,
  '--shivers': f.rattle / SHIVER_MS,
})

// Les paillettes projetées par le coffre.
// ⚠️ Angles en SPIRALE DORÉE (celle des graines de tournesol) et rayon en racine carrée :
// à 8 éclats la répartition régulière passait, à 60 elle dessinait une grille de rayons et
// d'anneaux. Là, la couverture est uniforme et rien ne s'aligne.
// Les départs et les durées sont étalés : on veut une pluie qui dure, pas un seul pop
// synchronisé — c'est ça, l'effet paillette.
const GOLDEN = Math.PI * (3 - Math.sqrt(5))
const burstOf = (n, k) => Array.from({ length: n }, (_, i) => {
  const angle = i * GOLDEN
  const dist = 70 + Math.sqrt((i + 1) / n) * 125
  return {
    dx: Math.round(Math.cos(angle) * dist),
    dy: Math.round(Math.sin(angle) * dist * 0.82) - 26,
    delay: (i % 9) * 0.09 * k,
    dur: (0.95 + (i % 5) * 0.2) * k,
    size: 10 + (i % 4) * 6,
    glyph: i % 4 === 0 ? '✨' : i % 4 === 1 ? '⭐' : i % 4 === 2 ? '●' : '·',
  }
})

// La pluie de pièces, elle, balaie tout l'écran : réparties sur la largeur, chacune avec
// sa vitesse et sa rotation pour qu'aucune ne tombe en rang avec sa voisine.
const rainOf = (n, k) => Array.from({ length: n }, (_, i) => ({
  x: Math.round(((i + 0.5) / n) * 100 + ((i % 3) - 1) * 5),
  delay: (i % 7) * 0.16 * k,
  dur: (1.6 + (i % 5) * 0.28) * k,
  size: 13 + (i % 4) * 4,
  spin: (i % 2 ? 1 : -1) * (240 + (i % 3) * 180),
  glyph: i % 4 === 0 ? '💎' : i % 4 === 3 ? '✨' : '🪙',
}))

// Le coffre, dessiné une fois pour toutes. C'est LE même dessin partout — la carte du sac,
// le titre de la section, la modal qui s'ouvre : on doit reconnaître au premier coup d'œil ce
// qu'on va ouvrir. Un 🎁 emoji promettait un cadeau, pas un coffre, et ne pouvait pas porter
// les ferrures de sa rareté.
export function ChestSvg({ open, shaking, popped, className = '' }) {
  const cls = ['chest-svg', className, shaking && 'shaking', popped && 'popped'].filter(Boolean).join(' ')
  return (
    <svg viewBox="0 0 120 100" className={cls} aria-hidden>
      {/* couvercle (charnière à l'arrière : il bascule vers le haut à l'ouverture) */}
      <g className={`chest-lid ${open ? 'open' : ''}`}>
        <path d="M18 46 Q18 18 60 18 Q102 18 102 46 Z" fill="#b5722f" stroke="#8a5420" strokeWidth="3" />
        {/* Le cerclage du couvercle : c'est LUI qui porte la rareté à petite taille — les
            ferrures verticales, elles, disparaissent sous 30 px. */}
        <rect x="18" y="39" width="84" height="7" className="chest-trim" />
        <rect x="52" y="28" width="16" height="18" rx="3" className="chest-trim" />
      </g>
      {/* corps */}
      <rect x="18" y="46" width="84" height="42" rx="8" fill="#c98a45" stroke="#8a5420" strokeWidth="3" />
      {/* ferrures */}
      <rect x="27" y="48" width="6" height="38" className="chest-trim" opacity=".75" />
      <rect x="87" y="48" width="6" height="38" className="chest-trim" opacity=".75" />
      <rect x="52" y="46" width="16" height="21" rx="3" className="chest-trim" />
    </svg>
  )
}

// Un gain qui sort du coffre : la pièce elle-même (son dessin ou son emoji) ou les 💎,
// dans un médaillon. Un cosmétique porte SA rareté, pas celle du coffre — c'est la seule
// autre couleur admise dans la modal, et elle est là pour ça : un coffre commun peut cracher
// un légendaire (voir Chest#open!), et ce moment-là doit se voir.
function Loot({ gain, delay }) {
  const cosmetic = gain.kind === 'cosmetic'
  return (
    <div className="chest-loot" style={{ animationDelay: `${delay}s` }}>
      <span className={`chest-loot-medal ${cosmetic ? `rar-${gain.rarity}` : ''}`}>
        {cosmetic
          ? <CosmeticIcon art={gain.art} emoji={gain.emoji} className="chest-loot-art" />
          : <span className="chest-loot-art">💎</span>}
      </span>
      <span className="chest-loot-name">{cosmetic ? gain.name : `+${gain.amount} 💎`}</span>
      {cosmetic && <span className="rar-pill">{rarityLabel(gain.rarity)}</span>}
      {gain.note && <span className="chest-loot-note">{gain.note}</span>}
    </div>
  )
}

// Phase révélation : la modal survit au rechargement grâce au flash. On mémorise le flash
// écarté (et pas un simple booléen) — sinon, le 2e coffre ouvert d'affilée s'ouvrirait muet.
export function ChestReveal() {
  const { flash } = usePage().props
  const [dismissed, setDismissed] = useState(null)
  const chest = flash?.chest && dismissed !== flash.chest ? flash.chest : null
  const rarity = chest?.rarity
  // Figé par rareté : la composition ne doit pas se redessiner à chaque rendu de React
  // pendant que les animations tournent.
  const fx = useMemo(() => {
    const f = fanfareOf(rarity)
    return { f, burst: burstOf(f.burst, f.k), rain: rainOf(f.coins, f.k) }
  }, [rarity])

  if (!chest) return null

  return (
    <div className={`chest-modal rar-${rarity}`} style={fxStyle(fx.f)}
         role="dialog" aria-label="Coffre ouvert">
      <span className="chest-flash" />
      {fx.rain.map((c, i) => (
        <span key={i} className="chest-coin" style={{
          '--x': `${c.x}%`, '--delay': `${c.delay}s`, '--dur': `${c.dur}s`,
          '--s': `${c.size}px`, '--spin': `${c.spin}deg`,
        }}>{c.glyph}</span>
      ))}
      <div className="chest-stage">
        <div className="chest-hold">
          <span className="chest-fx chest-rays" />
          <span className="chest-fx chest-glow" />
          <span className="chest-fx chest-beam" />
          <span className="chest-fx chest-shock" />
          <ChestSvg open popped />
          {fx.burst.map((p, i) => (
            <span key={i} className="chest-particle" style={{
              '--dx': `${p.dx}px`, '--dy': `${p.dy}px`, '--pd': `${p.dur}s`,
              fontSize: `${p.size}px`, animationDelay: `${p.delay}s`,
            }}>{p.glyph}</span>
          ))}
        </div>
        <div className="chest-gains-out">
          {chest.gains.map((g, i) => <Loot key={i} gain={g} delay={(0.45 + i * 0.32) * fx.f.k} />)}
        </div>
        <div className="chest-reveal-title">Coffre {rarityWord(rarity)} ouvert !</div>
        <button className="chest-btn" onClick={() => setDismissed(flash.chest)}>Récupérer 🎉</button>
      </div>
    </div>
  )
}

export default function ChestCard({ chest }) {
  const [opening, setOpening] = useState(false)

  if (!chest) return null

  const f = fanfareOf(chest.rarity)

  const open = () => {
    if (opening) return
    setOpening(true)
    const reduced = window.matchMedia('(prefers-reduced-motion: reduce)').matches
    setTimeout(() => router.post(`/coffres/${chest.id}/ouvrir`, {}, { preserveScroll: true }),
               reduced ? 0 : f.rattle)
  }

  return (
    <>
      {/* La carte ne trahit RIEN : ni pastille, ni teinte, ni ferrures colorées (sans
          `rar-*`, --rar n'est pas posé et .chest-trim retombe sur son or par défaut).
          La rareté n'existe qu'à partir du moment où on ouvre — c'est toute la tension. */}
      <div className="chest-card">
        <ChestSvg className="chest-mini" />
        <div className="chest-text">
          <div className="chest-title">Un coffre t'attend !</div>
          <div className="chest-sub">Trouvé sur une de tes courses.</div>
        </div>
        <button className="chest-btn" onClick={open}>Ouvrir</button>
      </div>
      {opening && (
        <div className={`chest-modal rar-${chest.rarity}`} style={fxStyle(f)}
             role="dialog" aria-label="Ouverture du coffre">
          <div className="chest-stage rattling">
            <div className="chest-hold">
              <span className="chest-fx chest-glow" />
              <ChestSvg shaking />
            </div>
            <div className="chest-reveal-title">Ouverture…</div>
          </div>
        </div>
      )}
    </>
  )
}
