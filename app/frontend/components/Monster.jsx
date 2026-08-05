import kcWear0 from '../assets/monsters/king-coco/wear0.webp'
import kcWear1 from '../assets/monsters/king-coco/wear1.webp'
import kcWear2 from '../assets/monsters/king-coco/wear2.webp'
import kcWear3 from '../assets/monsters/king-coco/wear3.webp'
import kcDefeated from '../assets/monsters/king-coco/defeated.webp'
import fbWear0 from '../assets/monsters/framboitrix/wear0.webp'
import fbWear1 from '../assets/monsters/framboitrix/wear1.webp'
import fbWear2 from '../assets/monsters/framboitrix/wear2.webp'
import fbWear3 from '../assets/monsters/framboitrix/wear3.webp'
import fbDefeated from '../assets/monsters/framboitrix/defeated.webp'

// Monstres des deux clans d'Odyssea. Le `slug` vient du back (Monster#slug) ; un slug inconnu
// retombe sur un emoji. Chaque monstre est une SÉRIE DE PLANCHES PEINTES (WebP détouré, 512²) :
// une illustration peinte ne se paramètre pas, donc chaque état est un fichier — et c'est ce
// qui permet le 5e, `defeated`, qu'on ne pouvait pas se payer quand les monstres étaient des
// SVG paramétrés : le monstre en morceaux au sol quand il tombe à 0 PV.
//
// Les modificateurs d'apparence, tous pilotés par la donnée du MonsterPresenter :
//   - `wear` (0→3) : paliers de PV franchis (75 / 50 / 25 %). Le monstre est de moins en moins
//     en forme. Cliquet côté back (Monster#refresh_state!) : un soin ne répare jamais les
//     dégâts déjà encaissés.
//   - `defeated` : monstre à 0 PV (state du présentateur). Passe sur la planche d'effondrement
//     quand il y en a une, sinon on reste au dernier palier d'usure.
//   - `creamed` : chantilly plein les yeux tant que l'effet dure (ses PV s'affichent « ??? »).
//   - `shielded` : saladier transparent retourné par-dessus (le monstre est intouchable).
//
// ⚠️ Les planches sont CARRÉES et cadrées comme la source : une surcouche SVG en viewBox
// 0 0 100 100 se pose donc dessus au pixel près. C'est ce qui permet à la chantilly et au
// saladier de rester du SVG par-dessus une image (voir `eyes`, relevé sur la planche).
// `size` : un nombre de pixels, ou n'importe quelle longueur CSS (le Hub passe « 100% » pour
// que le monstre remplisse son cadre, dont la hauteur vient d'un aspect-ratio).
export default function Monster({ slug, name, size = 96, className = '',
                                  wear = 0, creamed = false, shielded = false, defeated = false }) {
  const spec = MONSTERS[slug]
  const w = Math.min(3, Math.max(0, Math.round(wear) || 0))
  const box = { width: size, height: size }
  const label = describe(name || slug, w, creamed, shielded, defeated)

  if (!spec) {
    // `size` accepte un nombre (px) ou une longueur CSS — d'où le repli en % pour le glyphe.
    return (
      <span className={`mon ${className}`} style={box} role="img" aria-label={label}>
        <span style={{ fontSize: typeof size === 'number' ? size * 0.7 : '70%' }}>👾</span>
      </span>
    )
  }

  const src = (defeated && spec.art.defeated) || spec.art[w]
  return (
    <span className={`mon${w ? ` wear${w}` : ''} ${className}`} style={box} role="img" aria-label={label}>
      {/* Le bord arrière du saladier passe DERRIÈRE le monstre : il est dedans. */}
      {shielded && <svg viewBox="0 0 100 100" className="mon-layer"><BowlBack /></svg>}
      {/* Sous le saladier, le monstre rentre la tête dans les épaules. */}
      <span className={`mon-art-wrap${shielded ? ' tucked' : ''}`}>
        <img className="mon-svg mon-art" src={src} alt="" draggable={false} />
      </span>
      {(creamed || shielded) && (
        <svg viewBox="0 0 100 100" className="mon-layer front">
          {creamed && <Cream eyes={spec.eyes} />}
          {shielded && <SaladBowl />}
        </svg>
      )}
    </span>
  )
}

const WEAR_WORDS = ['', 'un peu amoché', 'mal en point', 'au bout du rouleau']

function describe(name, wear, creamed, shielded, defeated) {
  return [name, defeated ? 'vaincu, en morceaux' : WEAR_WORDS[wear],
          creamed && 'chantilly plein les yeux', shielded && 'sous un saladier']
    .filter(Boolean).join(', ')
}

// 🍦 Chantilly : deux belles noix de crème écrasées sur les yeux, avec la coulure qui dégouline.
// Tant que l'effet dure, le monstre n'y voit plus rien — et l'équipe visée non plus (PV « ??? »).
function Cream({ eyes }) {
  return (
    <g className="mon-cream">
      <CreamSwirl cx={eyes.left[0]} cy={eyes.left[1]} r={eyes.r} />
      <CreamSwirl cx={eyes.right[0]} cy={eyes.right[1]} r={eyes.r} />
    </g>
  )
}

function CreamSwirl({ cx, cy, r }) {
  const blobs = [
    [cx, cy + r * 0.22, r * 0.86],
    [cx - r * 0.52, cy + r * 0.02, r * 0.62],
    [cx + r * 0.52, cy + r * 0.05, r * 0.6],
    [cx - r * 0.16, cy - r * 0.52, r * 0.55],
    [cx + r * 0.3, cy - r * 0.6, r * 0.44],
    [cx + r * 0.04, cy - r * 1.02, r * 0.3]
  ]
  return (
    <g>
      {/* coulure sous l'œil */}
      <path d={`M${cx - r * 0.36} ${cy + r * 0.5} q${r * 0.08} ${r * 1.1} ${r * 0.36} ${r * 1.32}`
              + ` q${r * 0.28} -${r * 0.32} ${r * 0.3} -${r * 1.28} z`} fill="#fff" />
      <circle cx={cx + r * 0.42} cy={cy + r * 2.15} r={r * 0.2} fill="#fff" />
      {blobs.map(([x, y, rr], i) => <circle key={i} cx={x} cy={y} r={rr} fill="#fff" />)}
      {/* plis de la crème */}
      <g fill="none" stroke="#e6e0ea" strokeWidth={r * 0.15} strokeLinecap="round">
        <path d={`M${cx - r * 0.5} ${cy + r * 0.36} q${r * 0.5} ${r * 0.3} ${r} 0`} />
        <path d={`M${cx - r * 0.36} ${cy - r * 0.16} q${r * 0.42} ${r * 0.26} ${r * 0.78} -${r * 0.06}`} />
      </g>
    </g>
  )
}

// Bord arrière du saladier (la moitié haute de l'ouverture) : le monstre est DEDANS, donc ce
// bord-là passe derrière lui. Dessiné avant le monstre, la cloche vient par-dessus.
function BowlBack() {
  return (
    <g className="mon-bowl">
      <path d="M2 90 A48 6.5 0 0 1 98 90 Z" fill="#bfe6ff" opacity="0.45" />
      <path d="M2 90 A48 6.5 0 0 1 98 90" fill="none" stroke="#79c9ef" strokeWidth="2.6" opacity="0.9" />
    </g>
  )
}

// 🥣 Saladier retourné : cloche translucide posée sur le monstre, plus rien ne l'atteint.
// Seul le bord AVANT est ici — l'arrière est passé derrière le monstre (BowlBack).
function SaladBowl() {
  return (
    <g className="mon-bowl">
      <path d="M2 90 A48 72 0 0 1 98 90 Z" fill="#bfe6ff" opacity="0.3" />
      <path d="M2 90 A48 6.5 0 0 0 98 90 Z" fill="#bfe6ff" opacity="0.45" />
      <path d="M2 90 A48 72 0 0 1 98 90" fill="none" stroke="#79c9ef" strokeWidth="2.6" opacity="0.9" />
      <path d="M2 90 A48 6.5 0 0 0 98 90" fill="none" stroke="#79c9ef" strokeWidth="2.6" opacity="0.9" />
      {/* le pied du saladier, en l'air puisqu'il est retourné */}
      <ellipse cx="50" cy="19.5" rx="11" ry="3.2" fill="none" stroke="#79c9ef" strokeWidth="2.2" opacity="0.9" />
      {/* reflets sur le verre */}
      <g fill="none" stroke="#fff" strokeLinecap="round" opacity="0.6">
        <path d="M17 76 A42 60 0 0 1 30 32" strokeWidth="3.2" />
        <path d="M74 31 A42 60 0 0 1 84 56" strokeWidth="2" opacity="0.7" />
      </g>
    </g>
  )
}

// Le registre. `eyes` est le point de chute de la chantilly, en pourcentage de la boîte du
// monstre, relevé sur les planches — à resituer dès qu'une nouvelle série cadre le visage
// ailleurs, sinon la crème tombe à côté.
const MONSTERS = {
  'king-coco': {
    art: { 0: kcWear0, 1: kcWear1, 2: kcWear2, 3: kcWear3, defeated: kcDefeated },
    eyes: { left: [48, 43], right: [55, 43], r: 5 }
  },
  framboitrix: {
    art: { 0: fbWear0, 1: fbWear1, 2: fbWear2, 3: fbWear3, defeated: fbDefeated },
    eyes: { left: [47.5, 34.5], right: [56, 34.5], r: 5.5 }
  }
}
