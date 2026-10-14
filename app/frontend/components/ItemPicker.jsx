import { itemEmoji } from '../lib/gameIcons'

// Les power-ups du combat, en feuille du bas — la même que le choix d'une cible ou d'un
// monstre à barbouiller, pour qu'il n'y ait qu'un geste à apprendre.
//
// ⚠️ Un objet DÉJÀ EN COURS reste affiché, grisé et marqué « en cours », au lieu de
// disparaître : sinon on croit l'avoir perdu. C'est son effet qui tourne, pas l'objet qui a
// été consommé pour rien.
export default function ItemPicker({ items = [], onPick, onClose }) {
  return (
    <div className="tp-backdrop" onClick={onClose}>
      <div className="tp-sheet" onClick={(e) => e.stopPropagation()}>
        <div className="tp-title">🎒 Quel power-up ?</div>
        {items.length === 0
          ? <p className="tp-empty">Ton sac est vide. La boutique en vend contre des 🍑.</p>
          : items.map((it) => (
              <button key={it.id} className="tp-opt pk-item" onClick={() => onPick(it)}
                      disabled={it.active}>
                <span className="e">{itemEmoji(it.effect_type)}</span>
                <span className="n">{it.name}</span>
                {it.active && <span className="s">en cours</span>}
              </button>
            ))}
        <button className="tp-cancel" onClick={onClose}>Annuler</button>
      </div>
    </div>
  )
}
