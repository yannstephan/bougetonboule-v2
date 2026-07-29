// Le vocabulaire visuel du jeu : emojis et libellés partagés par plusieurs écrans.
// Une clé du back (effect_type, rarity, status, fruit_family, état d'un monstre) ne doit
// être traduite en emoji ou en mot qu'ici.

// Famille d'une équipe → son emoji de clan.
export const familyEmoji = (family) => (family === 'rouges' ? '🍒' : '🌴')

// Objet de la boutique → son emoji (Item#effect_type).
export const itemEmoji = (effectType) =>
  ({ shield: '🛡️', trap: '🐺', back_wind: '🌬️', face_wind: '🌪️', smoke: '🌫️', wooden_leg: '🦿' }[
    effectType
  ] || '🎒')

// Rareté d'un cosmétique ou d'un coffre (Cosmetic::RARITIES).
export const RARITY_LABEL = { common: 'commun', rare: 'rare', epic: 'épique', legendary: 'légendaire' }
export const rarityLabel = (rarity) => RARITY_LABEL[rarity] || rarity

// Statut d'une sortie (Training::STATUSES) → sa pastille.
const STATUS_CHIP = {
  verified: { label: 'Validée', cls: 'ok' },
  pending: { label: 'En attente', cls: 'wait' },
  rejected: { label: 'Rejetée', cls: 'no' },
  trapped: { label: 'Piégée', cls: 'no' },
  protected: { label: 'Protégée', cls: 'wait' },
}
export const statusChip = (status) => STATUS_CHIP[status] || STATUS_CHIP.pending

// État de santé d'un monstre → couleur de sa barre de PV (le même code pour les deux
// équipes : pas de « nous » en vert et « eux » en rouge).
export const hpClass = (state) =>
  ({ healthy: 'good', hurt: 'warn', critical: 'crit', defeated: 'crit' }[state] || 'good')
