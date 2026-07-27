// Feuille de sélection d'une équipe (fumigène : enfumer qui ?). Même style que TargetPicker.
export default function TeamPicker({ myTeam, foeTeam, onPick, onClose }) {
  return (
    <div className="tp-backdrop" onClick={onClose}>
      <div className="tp-sheet" onClick={(e) => e.stopPropagation()}>
        <div className="tp-title">🌫️ Enfumer quelle équipe ?</div>
        {foeTeam && (
          <button className="tp-opt" onClick={() => onPick('foe')}>
            {foeTeam} — ils ne verront plus les PV des monstres
          </button>
        )}
        <button className="tp-opt" onClick={() => onPick('mine')}>
          {myTeam} (nous) — écran de fumée sur notre propre camp
        </button>
        <button className="tp-cancel" onClick={onClose}>Annuler</button>
      </div>
    </div>
  )
}
