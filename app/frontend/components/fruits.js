// Catalogue visuel des fruits. La clé DOIT correspondre à app/models/fruit_catalog.rb :
// le back décide quels fruits une équipe propose, le front sait les dessiner.
//
// shape = silhouette SVG (voir FruitAvatar.jsx). Le reste = palette à plat.
export const FRUITS = {
  // — Fruits exotiques —
  ananas:    { shape: 'pineapple', body: '#f6b93b', dark: '#e58e26', leaf: '#3aa76d' },
  mangue:    { shape: 'oval',      body: '#f79f1f', dark: '#e17055', light: '#ffd45e', stem: '#3aa76d' },
  papaye:    { shape: 'pear',      body: '#f0932b', dark: '#e58e26', light: '#ffb84d', stem: '#3aa76d' },
  banane:    { shape: 'banana',    body: '#ffd93b', dark: '#e0a80c', tip: '#7a5a12' },
  passion:   { shape: 'round',     body: '#7b4397', dark: '#5b2c6f', stem: '#8a6d3b' },
  litchi:    { shape: 'round',     body: '#e8556d', dark: '#c0392b', bumpy: true, stem: '#8a6d3b' },
  kiwi:      { shape: 'oval',      body: '#8a6d3b', dark: '#6b5327', fuzzy: true, light: '#a3854a' },
  dragon:    { shape: 'dragon',    body: '#e84393', dark: '#c0286f', scale: '#3aa76d' },
  carambole: { shape: 'star',      body: '#f6c945', dark: '#d9a520', light: '#c8e05a' },
  goyave:    { shape: 'round',     body: '#7bc96f', dark: '#57964d', light: '#f39ba8', stem: '#3aa76d' },
  durian:    { shape: 'spiky',     body: '#c8b45a', dark: '#9a8636', spikeTone: '#8a7a2e' },
  corossol:  { shape: 'spiky',     body: '#8fce6f', dark: '#63a047', spikeTone: '#5a9440' },

  // — Fruits rouges —
  fraise:          { shape: 'strawberry', body: '#f0325b', dark: '#c81e45', leaf: '#3aa76d', seed: '#ffe08a' },
  fraise_des_bois: { shape: 'strawberry', body: '#d81b4a', dark: '#a5153a', leaf: '#2e8b57', seed: '#ffe08a', small: true },
  framboise:       { shape: 'berry',      body: '#e84370', dark: '#c0295a', drupTone: '#f06a90' },
  cerise:          { shape: 'round',      body: '#c0182f', dark: '#8e1122', stem: '#3aa76d', longStem: true },
  mure:            { shape: 'berry',      body: '#5b2a6b', dark: '#3e1c4a', drupTone: '#7a3f8c' },
  myrtille:        { shape: 'round',      body: '#4a5aa8', dark: '#2f3d7e', crown: true, dusty: '#8f9cd0' },
  groseille:       { shape: 'round',      body: '#e5334a', dark: '#b51f36', stem: '#8a6d3b', shiny: true },
  grenade:         { shape: 'pomegranate', body: '#c0182f', dark: '#8e1122', crownColor: '#8e1122', light: '#e5556b' },
  cranberry:       { shape: 'round',      body: '#a01427', dark: '#750e1c', shiny: true },
  goji:            { shape: 'oval',       body: '#e8443a', dark: '#bd2c24', light: '#ff7a5e' },
  sureau:          { shape: 'berry',      body: '#33224a', dark: '#1e1430', drupTone: '#4a3568' },
}

export const FRUIT_KEYS = Object.keys(FRUITS)

// Palette de secours quand une clé n'a pas (encore) de rendu dédié.
export const FALLBACK_FRUIT = { shape: 'round', body: '#ff7a59', dark: '#e0603f' }

export const fruitParams = (key) => FRUITS[key] || FALLBACK_FRUIT
