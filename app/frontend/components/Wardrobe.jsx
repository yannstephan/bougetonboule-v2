import { useState } from 'react'
import PlayerAvatar from './PlayerAvatar'
import { CosmeticIcon } from './cosmeticArt'

// L'armoire : l'aperçu de l'avatar reste collé en haut (`.av-sticky`) pendant qu'on fouille,
// un onglet par emplacement, et le rayon n'affiche que les pièces de l'emplacement choisi.
// Empiler tout le catalogue d'un coup obligeait à scroller entre la pièce et l'avatar.
// Vit dans le sac (/sac, onglet 🎨) — le seul endroit d'où l'on équipe.
const SLOTS = {
  hat: { label: 'Chapeau', icon: '🎩' },
  eyes: { label: 'Lunettes', icon: '👓' },
  neck: { label: 'Cou', icon: '🧣' },
  hands: { label: 'Bras', icon: '🦾' },
  shoes: { label: 'Chaussures', icon: '👟' },
  sidekick: { label: 'Accessoire', icon: '🐕' },
  aura: { label: 'Aura', icon: '✨' },
}

export default function Wardrobe({ avatar, cosmetics, slots, onToggle }) {
  const [tab, setTab] = useState(slots[0] || 'hat')
  const active = slots.includes(tab) ? tab : slots[0]
  const inSlot = (slot) => cosmetics.filter((c) => c.slot === slot)

  return (
    <>
      <div className="av-sticky">
        <div className="av-stage"><PlayerAvatar avatar={avatar} size={132} /></div>
        <div className="av-tabs">
          {slots.map((key) => (
            <button key={key} className={`av-tab ${active === key ? 'on' : ''}`} onClick={() => setTab(key)}>
              <span className="ic">{SLOTS[key]?.icon || '🎁'}</span>
              <span className="tn">{SLOTS[key]?.label || key}</span>
              {inSlot(key).some((c) => c.equipped) && <span className="dot" />}
            </button>
          ))}
        </div>
      </div>
      <SlotRack slot={active} list={inSlot(active)} onToggle={onToggle} />
    </>
  )
}

// Le rayon d'un emplacement : les pièces possédées, plus une case « Retirer » quand
// quelque chose est équipé — sinon il faut retrouver la pièce portée pour l'enlever.
function SlotRack({ slot, list, onToggle }) {
  const worn = list.find((c) => c.equipped)

  if (list.length === 0) {
    return (
      <section className="av-sec">
        <h2>{SLOTS[slot]?.label || slot}</h2>
        <p className="av-empty">
          Rien dans cet emplacement pour l'instant. Les cosmétiques s'achètent en 💎 à la
          boutique, ou se gagnent (série hebdo, coffres, 1er du classement du mois).
        </p>
      </section>
    )
  }

  return (
    <section className="av-sec">
      <h2>{SLOTS[slot]?.label || slot} · {list.length}</h2>
      <div className="av-rack">
        {worn && (
          <button className="av-card bare" onClick={() => onToggle(worn)}>
            <span className="e">🚫</span>
            <span className="n">Retirer</span>
          </button>
        )}
        {list.map((c) => (
          <button key={c.id} className={`av-card ${c.rarity} ${c.equipped ? 'on' : ''}`}
                  onClick={() => onToggle(c)}>
            <CosmeticIcon art={c.art} emoji={c.emoji} className="e" />
            <span className="n">{c.name}</span>
            {c.equipped && <span className="tick">✓</span>}
          </button>
        ))}
      </div>
    </section>
  )
}
