import PlayerAvatar from './PlayerAvatar'
import { CosmeticIcon } from './cosmeticArt'

// Confirmation d'achat. On ne dépense jamais une monnaie gagnée en courant sur un geste
// involontaire : la feuille rappelle CE qu'on achète, CE que ça coûte et CE qu'il restera.
//
// Reprend la feuille du bas des autres choix du jeu (TargetPicker, MonsterPicker) plutôt qu'un
// `confirm()` natif : c'est un moment de la boutique, il mérite de montrer la pièce.
// Pour un cosmétique, on la montre PORTÉE — c'est ce qu'on achète vraiment, pas une vignette.
export default function BuyConfirm({ buy, avatar, onConfirm, onClose }) {
  if (!buy) return null

  const { name, price, currency, emoji, art, slot, description } = buy
  const cosmetic = currency === '💎'
  const balance = buy.balance ?? 0
  const left = balance - price
  const preview = cosmetic && avatar?.fruit
    ? { ...avatar, cosmetics: { ...avatar.cosmetics, [slot]: { emoji, art } } }
    : null

  return (
    <div className="tp-backdrop" onClick={onClose}>
      <div className="tp-sheet" onClick={(e) => e.stopPropagation()}>
        <div className="tp-title">Confirmer l'achat</div>

        <div className="buy-what">
          {preview
            ? <PlayerAvatar avatar={preview} size={96} />
            : <CosmeticIcon art={art} emoji={emoji} className="buy-icon" />}
          <div className="buy-id">
            <div className="buy-name">{name}</div>
            {description && <div className="buy-desc">{description}</div>}
          </div>
        </div>

        <div className="buy-sum">
          <span>Prix</span><b>{price} {currency}</b>
          <span>Il te restera</span><b>{left} {currency}</b>
        </div>

        <button className="btn primary" onClick={onConfirm}>Acheter pour {price} {currency}</button>
        <button className="tp-cancel" onClick={onClose}>Annuler</button>
      </div>
    </div>
  )
}
