// Catalogue visuel des fruits. La clé DOIT correspondre à app/models/fruit_catalog.rb :
// le back décide quels fruits une équipe propose, le front sait les dessiner.
//
// shape = silhouette SVG (voir FruitAvatar.jsx). Le reste = palette à plat.
//
// `box` = les repères de la silhouette dans le viewBox 0-100, d'où FruitAvatar déduit
// les ancres des cosmétiques. C'est ce qui fait qu'un chapeau se pose sur le sommet
// RÉEL du fruit et pas dans le vide, et que les gants tombent à sa vraie largeur :
//   top    — la ligne du crâne : le chapeau s'y pose
//   bottom — la ligne du sol : les chaussures s'y posent, l'écharpe juste au-dessus
//   half   — la demi-largeur : gants et accessoire s'écartent de là
//   hatX   — (optionnel) abscisse du sommet quand il n'est pas au centre (banane)
const BOX = (top, bottom, half, hatX = 50) => ({ top, bottom, half, hatX })

export const FRUITS = {
  // — Fruits exotiques —
  ananas:    { shape: 'pineapple', body: '#f6b93b', dark: '#e58e26', leaf: '#3aa76d', box: BOX(34, 88, 25) },
  mangue:    { shape: 'oval',      body: '#f79f1f', dark: '#e17055', light: '#ffd45e', stem: '#3aa76d', box: BOX(25, 88, 24) },
  papaye:    { shape: 'pear',      body: '#f0932b', dark: '#e58e26', light: '#ffb84d', stem: '#3aa76d', box: BOX(27, 88, 15) },
  banane:    { shape: 'banana',    body: '#ffd93b', dark: '#e0a80c', tip: '#7a5a12', box: BOX(31, 84, 26, 46) },
  passion:   { shape: 'round',     body: '#7b4397', dark: '#5b2c6f', stem: '#8a6d3b', box: BOX(27, 86, 30) },
  litchi:    { shape: 'round',     body: '#e8556d', dark: '#c0392b', bumpy: true, stem: '#8a6d3b', box: BOX(27, 86, 30) },
  kiwi:      { shape: 'oval',      body: '#8a6d3b', dark: '#6b5327', fuzzy: true, light: '#a3854a', box: BOX(25, 88, 24) },
  dragon:    { shape: 'dragon',    body: '#e84393', dark: '#c0286f', scale: '#3aa76d', box: BOX(27, 88, 24) },
  carambole: { shape: 'star',      body: '#f6c945', dark: '#d9a520', light: '#c8e05a', box: BOX(24, 80, 31) },
  goyave:    { shape: 'round',     body: '#7bc96f', dark: '#57964d', light: '#f39ba8', stem: '#3aa76d', box: BOX(27, 86, 30) },
  durian:    { shape: 'spiky',     body: '#c8b45a', dark: '#9a8636', spikeTone: '#8a7a2e', box: BOX(24, 88, 32) },
  corossol:  { shape: 'spiky',     body: '#8fce6f', dark: '#63a047', spikeTone: '#5a9440', box: BOX(24, 88, 32) },

  // — Fruits rouges —
  fraise:          { shape: 'strawberry', body: '#f0325b', dark: '#c81e45', leaf: '#3aa76d', seed: '#ffe08a', box: BOX(25, 86, 22) },
  fraise_des_bois: { shape: 'strawberry', body: '#d81b4a', dark: '#a5153a', leaf: '#2e8b57', seed: '#ffe08a', small: true, box: BOX(29, 82, 19) },
  cassis:          { shape: 'round',      body: '#3a2352', dark: '#22132f', crown: true, dusty: '#8f6fb0', shiny: true, box: BOX(26, 86, 30) },
  cerise:          { shape: 'round',      body: '#c0182f', dark: '#8e1122', stem: '#3aa76d', longStem: true, box: BOX(27, 86, 30) },
  mure:            { shape: 'berry',      body: '#5b2a6b', dark: '#3e1c4a', drupTone: '#7a3f8c', box: BOX(25, 84, 24) },
  myrtille:        { shape: 'round',      body: '#4a5aa8', dark: '#2f3d7e', crown: true, dusty: '#8f9cd0', box: BOX(26, 86, 30) },
  groseille:       { shape: 'round',      body: '#e5334a', dark: '#b51f36', stem: '#8a6d3b', shiny: true, box: BOX(27, 86, 30) },
  grenade:         { shape: 'pomegranate', body: '#c0182f', dark: '#8e1122', crownColor: '#8e1122', light: '#e5556b', box: BOX(28, 87, 29) },
  cranberry:       { shape: 'round',      body: '#a01427', dark: '#750e1c', shiny: true, box: BOX(27, 86, 30) },
  goji:            { shape: 'oval',       body: '#e8443a', dark: '#bd2c24', light: '#ff7a5e', box: BOX(25, 88, 24) },
  sureau:          { shape: 'berry',      body: '#33224a', dark: '#1e1430', drupTone: '#4a3568', box: BOX(25, 84, 24) },
}

export const FRUIT_KEYS = Object.keys(FRUITS)

// Palette de secours quand une clé n'a pas (encore) de rendu dédié.
export const FALLBACK_FRUIT = { shape: 'round', body: '#ff7a59', dark: '#e0603f', box: BOX(27, 86, 30) }

export const fruitParams = (key) => FRUITS[key] || FALLBACK_FRUIT

export const fruitBox = (key) => (FRUITS[key] || FALLBACK_FRUIT).box || FALLBACK_FRUIT.box
