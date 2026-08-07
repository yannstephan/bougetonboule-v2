import { CosmeticIcon } from './cosmeticArt'

// Le FOND DE PAGE porte l'aura : ses petits motifs semés partout, très pâles.
//
// C'est là qu'a atterri l'aura après avoir été une couronne serrée derrière l'avatar. Dans
// un cadre de taille fixe, on ne pouvait pas l'élargir sans la faire sortir du cadre : une
// aura veut de la place, la page en a, l'avatar non.
//
// ⚠️ « Pour soi » : chacun voit la SIENNE, partout dans le jeu. Sur le profil d'un joueur,
// c'est la sienne qu'on voit (`page_aura`, servi par ProfilesController) — cliquer sur
// quelqu'un, c'est entrer chez lui, et c'est son aura qui donne l'ambiance à sa page.
//
// Semis déterministe : une grille décalée d'une demi-case une ligne sur deux, plus un petit
// déport et une inclinaison par motif. En grille pure ça faisait du papier millimétré ; au
// hasard, les motifs se regroupaient en paquets et laissaient des trous.
const COLS = 6
const ROWS = 9
const MOTIFS = Array.from({ length: COLS * ROWS }, (_, i) => {
  const col = i % COLS
  const row = Math.floor(i / COLS)
  return {
    left: (col * 100) / COLS + (row % 2 ? 50 / COLS : 0) + ((i % 3) - 1) * 2.4,
    top: (row * 100) / ROWS + ((i % 4) - 1.5) * 1.6,
    size: 20 + (i % 3) * 7,
    tilt: ((i % 5) - 2) * 9,
  }
})

// `local` : la même chose, mais bornée à son conteneur et plus franche — c'est ce qui rend
// l'essayage d'une aura visible dans la cabine et l'armoire, où l'on n'a pas encore changé
// le fond du site.
export default function AuraBackground({ aura, local = false }) {
  if (!aura?.emoji && !aura?.art) return null

  return (
    <div className={`aura-bg${local ? ' local' : ''}`} aria-hidden>
      {MOTIFS.map((m, i) => (
        <span key={i} className="aura-motif" style={{
          left: `${m.left}%`, top: `${m.top}%`,
          fontSize: `${m.size}px`, transform: `rotate(${m.tilt}deg)`,
        }}>
          <CosmeticIcon art={aura.art} emoji={aura.emoji} className="aura-glyph" />
        </span>
      ))}
    </div>
  )
}
