import FruitAvatar from './FruitAvatar'
import { CosmeticIcon } from './cosmeticArt'

// Avatar d'un joueur, utilisé partout (Hub, chat, classement, écran avatar).
// Sans fruit choisi (joueur pas encore en équipe), on affiche une pastille neutre
// avec l'initiale — les cosmétiques éventuels restent visibles.
export default function PlayerAvatar({ avatar, size = 36, showCosmetics = true }) {
  if (!avatar) return null
  if (!avatar.fruit) return <Placeholder avatar={avatar} size={size} showCosmetics={showCosmetics} />

  return (
    <FruitAvatar fruit={avatar.fruit} size={size} cosmetics={avatar.cosmetics} showCosmetics={showCosmetics} />
  )
}

function Placeholder({ avatar, size, showCosmetics }) {
  return (
    <span className="fav" style={{ width: size, height: size, fontSize: size }}>
      <span className="fav-blank">{avatar.initial || '🍑'}</span>
      {showCosmetics && avatar.cosmetics?.hat && (
        <CosmeticIcon art={avatar.cosmetics.hat.art} emoji={avatar.cosmetics.hat.emoji}
                      className="fav-slot fav-hat"
                      style={{ left: '50%', top: '18%', fontSize: '.36em' }} />
      )}
    </span>
  )
}
