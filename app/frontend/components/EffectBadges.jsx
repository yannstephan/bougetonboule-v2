import { useState } from 'react'

// Effets actifs d'une équipe, visibles par tout le monde : chacun avec son échéance.
// Rien à afficher = rien (pas de cadre vide).
//
// `compact` sert l'arène du Hub, où les deux camps se partagent la largeur d'un téléphone :
// on y réduit les effets à leur LOGO, en pastilles rondes sur une ou deux lignes. Écrit en
// toutes lettres, un camp bien garni prenait cinq lignes et poussait le monstre hors de l'écran.
//
// Deux réponses au fait qu'un emoji seul ne se comprend pas toujours :
//   - les effets marqués `labelled` par le presenter GARDENT leur texte, sur leur propre ligne
//     sous les logos — c'est le cas du palier de meute, dont le libellé porte un chiffre ;
//   - les autres sont des BOUTONS : au toucher, l'effet s'explique sur une ligne en dessous.
//     Le `title` seul ne suffisait pas — une infobulle de survol n'existe pas sur mobile.
export default function EffectBadges({ effects, label, compact = false }) {
  const [openKind, setOpenKind] = useState(null)

  if (!effects || effects.length === 0) return null

  if (!compact) {
    return (
      <div className="fx-line">
        {label && <span className="fx-label">{label}</span>}
        <div className="fx-row">
          {effects.map((e, i) => (
            <span key={i} className="fx" title={effectTitle(e)}>
              <span className="fx-e">{e.emoji}</span>
              <span className="fx-t">
                {e.name}
                {e.until && <b> · {e.until}{e.remaining ? ` (${e.remaining})` : ''}</b>}
              </span>
            </span>
          ))}
        </div>
      </div>
    )
  }

  const logos = effects.filter((e) => !e.labelled)
  const labelled = effects.filter((e) => e.labelled)
  const open = logos.find((e) => e.kind === openKind)

  return (
    <div className="fx-line compact">
      {logos.length > 0 && (
        <div className="fx-row">
          {logos.map((e, i) => (
            <button key={i} type="button" className={`fx fx-btn ${open === e ? 'on' : ''}`}
                    aria-label={effectTitle(e)} aria-pressed={open === e}
                    onClick={() => setOpenKind(open === e ? null : e.kind)}>
              <span className="fx-e">{e.emoji}</span>
            </button>
          ))}
        </div>
      )}
      {labelled.map((e, i) => (
        <span key={i} className="fx" title={effectTitle(e)}>
          <span className="fx-e">{e.emoji}</span>
          <span className="fx-t">{e.name}</span>
        </span>
      ))}
      {open && (
        <p className="fx-detail">
          {open.name}{open.remaining ? ` · encore ${open.remaining}` : ''}
        </p>
      )}
    </div>
  )
}

function effectTitle(e) {
  return [e.name, e.remaining && `encore ${e.remaining}`, e.until, e.by && `posé par ${e.by}`]
    .filter(Boolean).join(' · ')
}
