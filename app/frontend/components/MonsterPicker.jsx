// Feuille de sélection du fumigène : l'adversaire est toujours aveuglé, on choisit QUEL monstre
// lui masquer — le sien ('foe') ou le nôtre ('mine').
export default function MonsterPicker({ myMonster, foeMonster, foeTeam, onPick, onClose }) {
  const who = foeTeam || "l'adversaire"
  return (
    <div className="tp-backdrop" onClick={onClose}>
      <div className="tp-sheet" onClick={(e) => e.stopPropagation()}>
        <div className="tp-title">🌫️ Masquer quel monstre à {who} ?</div>
        {foeMonster && (
          <button className="tp-opt" onClick={() => onPick('foe')}>
            {foeMonster} — {who} ne verra plus les PV de son propre monstre
          </button>
        )}
        {myMonster && (
          <button className="tp-opt" onClick={() => onPick('mine')}>
            {myMonster} (nous) — {who} ne verra plus les PV de notre monstre
          </button>
        )}
        <button className="tp-cancel" onClick={onClose}>Annuler</button>
      </div>
    </div>
  )
}
