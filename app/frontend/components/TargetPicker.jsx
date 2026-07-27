// Feuille de sélection d'un adversaire à piéger. Personne d'autre ne verra la cible :
// l'annonce publique reste « X a posé un piège à loup ».
export default function TargetPicker({ opponents = [], onPick, onClose }) {
  return (
    <div className="tp-backdrop" onClick={onClose}>
      <div className="tp-sheet" onClick={(e) => e.stopPropagation()}>
        <div className="tp-title">🐺 Piéger quel adversaire ?</div>
        {opponents.length === 0
          ? <p className="tp-empty">Aucun adversaire à piéger.</p>
          : opponents.map((o) => (
              <button key={o.id} className="tp-opt" onClick={() => onPick(o.id)}>{o.name}</button>
            ))}
        <button className="tp-cancel" onClick={onClose}>Annuler</button>
      </div>
    </div>
  )
}
