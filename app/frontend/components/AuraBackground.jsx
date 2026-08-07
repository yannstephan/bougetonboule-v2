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
// ⚠️ Deux semis, et pas un seul mis à l'échelle : la page fait plusieurs centaines de pixels
// de haut, l'aperçu de la cabine à peine 180. La même densité donnait un banc de poissons
// serré dans l'aperçu — un motif de fond doit RESPIRER, sinon il devient le sujet.
const grid = (cols, rows, base) => Array.from({ length: cols * rows }, (_, i) => {
  const col = i % cols
  const row = Math.floor(i / cols)
  return {
    left: (col * 100) / cols + (row % 2 ? 50 / cols : 0) + ((i % 3) - 1) * 2.4,
    top: (row * 100) / rows + ((i % 4) - 1.5) * 1.8,
    size: base + (i % 3) * 6,
    tilt: ((i % 5) - 2) * 9,
  }
})
const PAGE_MOTIFS = grid(4, 6, 22)
const LOCAL_MOTIFS = grid(3, 2, 26)

// `local` : la même chose, mais bornée à son conteneur et plus franche — c'est ce qui rend
// l'essayage d'une aura visible dans la cabine et l'armoire, où l'on n'a pas encore changé
// le fond du site.
export default function AuraBackground({ aura, local = false }) {
  if (!aura?.emoji && !aura?.art) return null

  return (
    <div className={`aura-bg${local ? ' local' : ''}`} aria-hidden>
      {(local ? LOCAL_MOTIFS : PAGE_MOTIFS).map((m, i) => (
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
