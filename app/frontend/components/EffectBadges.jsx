// Effets actifs d'une équipe, visibles par tout le monde : chacun avec son échéance.
// Rien à afficher = rien (pas de cadre vide).
export default function EffectBadges({ effects, label }) {
  if (!effects || effects.length === 0) return null

  return (
    <div className="fx-line">
      {label && <span className="fx-label">{label}</span>}
      <div className="fx-row">
        {effects.map((e, i) => (
          <span key={i} className="fx" title={e.by ? `posé par ${e.by}` : ''}>
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
