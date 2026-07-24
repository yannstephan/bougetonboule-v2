// Avatar d'un joueur : pastille de couleur + personnage, avec les cosmétiques équipés
// posés par-dessus. Utilisé dans le Hub, le chat, le classement et l'écran avatar.
export default function PlayerAvatar({ avatar, size = 36, showCosmetics = true }) {
  if (!avatar) return null
  const { color, face, cosmetics = {} } = avatar

  return (
    <span className="pav" style={{ '--pav-size': `${size}px`, background: `var(--${color})` }}>
      <span className="pav-face">{face}</span>
      {showCosmetics && cosmetics.aura && <span className="pav-aura">{cosmetics.aura}</span>}
      {showCosmetics && cosmetics.hat && <span className="pav-hat">{cosmetics.hat}</span>}
      {showCosmetics && cosmetics.eyes && <span className="pav-eyes">{cosmetics.eyes}</span>}
    </span>
  )
}
