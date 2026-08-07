// Les emojis qui identifient un objet de combat. Ils étaient recopiés à l'identique dans la
// boutique, le sac et le combat : ajouter un objet demandait de penser aux trois. Un seul
// endroit, donc, et la même règle que le reste du jeu — l'emoji EST l'identité de l'objet
// (voir la variante compacte des effets sur le Hub).
export const itemEmoji = (effectType) =>
  ({ shield: '🥣', trap: '🐺', back_wind: '🌬️', face_wind: '🌪️', smoke: '🍦', wooden_leg: '🦿' }[effectType] || '🎒')

// Le clan d'une équipe, d'après sa famille de fruits.
export const familyEmoji = (family) => (family === 'rouges' ? '🍒' : '🌴')
