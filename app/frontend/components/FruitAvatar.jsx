import { fruitParams } from './fruits'

// Avatar-fruit : une silhouette SVG (par fruit) + un visage partagé (mêmes yeux/nez/bouche
// pour tous) + des cosmétiques posés à des ancres fixes. Comme le visage et les ancres ne
// bougent pas d'un fruit à l'autre, un chapeau ou des lunettes gagnés tombent toujours au
// bon endroit, quel que soit le fruit.
//
// viewBox 100×100, corps centré autour de (50,55), visage autour de (50,54).
// Slots dessinés DERRIÈRE le fruit (aura) puis DEVANT (ordre d'empilement du bas vers le haut).
// Ajouter un slot cosmétique = une entrée ici + son ancre CSS (.fav-<slot>). Aucun autre code :
// une fois le slot connu, un nouveau cosmétique n'est qu'une ligne en base (Cosmetic + emoji).
const BACK_SLOTS = ['aura']
const FRONT_SLOTS = ['legs', 'outfit', 'arms', 'eyes', 'hat']

export default function FruitAvatar({ fruit, size = 96, cosmetics = {}, showCosmetics = true, face = true }) {
  const p = fruitParams(fruit)
  const worn = (slots) => (showCosmetics ? slots.filter((s) => cosmetics[s]) : [])

  return (
    <span className="fav" style={{ width: size, height: size, fontSize: size }}>
      {worn(BACK_SLOTS).map((s) => <Cosmetic key={s} slot={s} emoji={cosmetics[s]} />)}
      <svg viewBox="0 0 100 100" className="fav-svg" role="img" aria-label={fruit || 'fruit'}>
        <Body p={p} />
        {face && <Face />}
      </svg>
      {worn(FRONT_SLOTS).map((s) => <Cosmetic key={s} slot={s} emoji={cosmetics[s]} />)}
    </span>
  )
}

// Emojis de bras qui représentent DÉJÀ une paire (gants) : on les pose une seule fois, centrés,
// au lieu de les refléter à gauche ET à droite — sinon on obtient deux mains de chaque côté.
const PAIR_ARM_EMOJIS = ['🧤']

// Un cosmétique posé à son ancre. Les bras sont symétriques : un emoji, rendu à gauche et à droite
// (sauf un emoji-paire, posé une seule fois).
function Cosmetic({ slot, emoji }) {
  if (slot === 'arms') {
    if (PAIR_ARM_EMOJIS.includes(emoji)) {
      return <span className="fav-arm fav-arm-pair">{emoji}</span>
    }
    return (
      <>
        <span className="fav-arm fav-arm-l">{emoji}</span>
        <span className="fav-arm fav-arm-r">{emoji}</span>
      </>
    )
  }
  return <span className={`fav-${slot}`}>{emoji}</span>
}

// Visage commun à tous les fruits.
function Face() {
  return (
    <g className="fav-face">
      <ellipse cx="40" cy="52" rx="7" ry="7.5" fill="#fff" />
      <ellipse cx="60" cy="52" rx="7" ry="7.5" fill="#fff" />
      <circle cx="41.5" cy="53" r="3.4" fill="#2b2333" />
      <circle cx="61.5" cy="53" r="3.4" fill="#2b2333" />
      <circle cx="40" cy="51.5" r="1.1" fill="#fff" />
      <circle cx="60" cy="51.5" r="1.1" fill="#fff" />
      <path d="M47 60 Q50 63 53 60" fill="none" stroke="#2b2333" strokeWidth="1.6" strokeLinecap="round" />
      <path d="M43 66 Q50 73 57 66" fill="none" stroke="#2b2333" strokeWidth="2.2" strokeLinecap="round" />
      <ellipse cx="32" cy="61" rx="4" ry="2.6" fill="#ff8fa3" opacity="0.55" />
      <ellipse cx="68" cy="61" rx="4" ry="2.6" fill="#ff8fa3" opacity="0.55" />
    </g>
  )
}

function Body({ p }) {
  const Shape = SHAPES[p.shape] || SHAPES.round
  return <Shape p={p} />
}

// ————— Silhouettes —————

const Round = ({ p }) => (
  <g>
    {p.stem && <Stem long={p.longStem} color={p.stem} />}
    {p.crown && <path d="M50 24 l5 -8 l5 8 l6 -6 l1 8 z" fill={p.dark} />}
    <circle cx="50" cy="56" r="30" fill={p.body} />
    <path d="M30 44 a30 30 0 0 1 24 -10" fill="none" stroke="#fff" strokeOpacity={p.shiny ? 0.5 : 0.28}
          strokeWidth="5" strokeLinecap="round" />
    {p.bumpy && <Bumps color={p.dark} />}
    {p.fuzzy && <circle cx="50" cy="56" r="30" fill="none" stroke={p.dark} strokeWidth="2" strokeDasharray="1 3" />}
    {p.dusty && <circle cx="50" cy="56" r="30" fill={p.dusty} opacity="0.18" />}
  </g>
)

const Oval = ({ p }) => (
  <g>
    {p.stem && <Stem color={p.stem} />}
    <ellipse cx="50" cy="56" rx="24" ry="32" fill={p.body} />
    {p.light && <ellipse cx="42" cy="44" rx="7" ry="12" fill={p.light} opacity="0.55" />}
    {p.fuzzy && <ellipse cx="50" cy="56" rx="24" ry="32" fill="none" stroke={p.dark} strokeWidth="2" strokeDasharray="1 3" />}
  </g>
)

const Pear = ({ p }) => (
  <g>
    {p.stem && <Stem color={p.stem} />}
    <path d="M50 26 C64 26 60 48 62 60 C64 78 54 88 50 88 C46 88 36 78 38 60 C40 48 36 26 50 26 Z"
          fill={p.body} />
    {p.light && <ellipse cx="43" cy="52" rx="6" ry="14" fill={p.light} opacity="0.5" />}
  </g>
)

const Strawberry = ({ p }) => {
  const scale = p.small ? 0.86 : 1
  return (
    <g transform={`translate(50 54) scale(${scale}) translate(-50 -54)`}>
      <path d="M50 30 C68 30 74 42 72 54 C70 68 58 86 50 86 C42 86 30 68 28 54 C26 42 32 30 50 30 Z"
            fill={p.body} />
      <Seeds color={p.seed} />
      <g fill={p.leaf}>
        <path d="M50 22 C44 26 38 27 33 26 C39 33 44 34 50 33 Z" />
        <path d="M50 22 C56 26 62 27 67 26 C61 33 56 34 50 33 Z" />
        <path d="M50 20 C47 25 46 29 47 33 L53 33 C54 29 53 25 50 20 Z" />
      </g>
    </g>
  )
}

const Berry = ({ p }) => {
  const drups = [
    [50, 34], [41, 42], [59, 42], [36, 54], [50, 50], [64, 54],
    [42, 65], [58, 65], [50, 74],
  ]
  return (
    <g>
      <Stem color="#3aa76d" small />
      {drups.map(([x, y], i) => (
        <circle key={i} cx={x} cy={y} r="9.5" fill={i % 2 ? p.drupTone : p.body} stroke={p.dark}
                strokeWidth="1" />
      ))}
    </g>
  )
}

const Banana = ({ p }) => (
  <g>
    <path d="M26 34 C22 58 34 80 62 82 C74 82 80 76 80 74 C74 78 60 74 48 62 C36 50 36 40 40 32 C34 30 28 30 26 34 Z"
          fill={p.body} stroke={p.dark} strokeWidth="1.5" />
    <path d="M60 80 l6 4" stroke={p.tip} strokeWidth="4" strokeLinecap="round" />
    <path d="M40 32 l-2 -6" stroke={p.tip} strokeWidth="4" strokeLinecap="round" />
  </g>
)

const Star = ({ p }) => {
  const pts = starPoints(50, 55, 34, 15, 5, -90)
  return (
    <g>
      <polygon points={pts} fill={p.body} stroke={p.dark} strokeWidth="1.5" strokeLinejoin="round" />
      <polygon points={starPoints(50, 55, 16, 7, 5, -90)} fill={p.light} opacity="0.4" />
    </g>
  )
}

const Pineapple = ({ p }) => (
  <g>
    <g fill={p.leaf} stroke="#2e8b57" strokeWidth="0.8">
      <path d="M50 30 C46 14 42 10 40 6 C40 18 42 24 46 30 Z" />
      <path d="M50 30 C54 14 58 10 60 6 C60 18 58 24 54 30 Z" />
      <path d="M50 28 C48 12 50 8 50 4 C52 10 52 18 50 28 Z" />
    </g>
    <ellipse cx="50" cy="60" rx="25" ry="28" fill={p.body} />
    <g stroke={p.dark} strokeWidth="1.3" opacity="0.7">
      <path d="M34 46 L66 74 M42 42 L70 66 M30 54 L58 82 M50 40 L74 60 M32 66 L52 84" />
      <path d="M66 46 L34 74 M58 42 L30 66 M70 54 L42 82 M50 40 L26 60 M68 66 L48 84" />
    </g>
  </g>
)

const Spiky = ({ p }) => {
  const spikes = starPoints(50, 56, 33, 25, 14, -90)
  return (
    <g>
      <polygon points={spikes} fill={p.spikeTone} />
      <circle cx="50" cy="56" r="24" fill={p.body} />
      <circle cx="50" cy="56" r="24" fill="none" stroke={p.dark} strokeWidth="1.5" strokeDasharray="2 4" />
    </g>
  )
}

const Dragon = ({ p }) => (
  <g>
    <ellipse cx="50" cy="57" rx="24" ry="31" fill={p.body} />
    <g fill={p.scale} stroke="#2e8b57" strokeWidth="0.6">
      <path d="M30 40 l-10 -6 l6 10 z" />
      <path d="M70 40 l10 -6 l-6 10 z" />
      <path d="M28 60 l-11 -2 l8 8 z" />
      <path d="M72 60 l11 -2 l-8 8 z" />
      <path d="M40 32 l-4 -11 l9 6 z" />
      <path d="M60 32 l4 -11 l-9 6 z" />
    </g>
    <ellipse cx="43" cy="46" rx="5" ry="10" fill="#fff" opacity="0.35" />
  </g>
)

const Pomegranate = ({ p }) => (
  <g>
    <path d="M50 22 l4 -6 l4 5 l5 -3 l-2 8 z" fill={p.crownColor} />
    <circle cx="50" cy="58" r="29" fill={p.body} />
    {p.light && <ellipse cx="40" cy="46" rx="7" ry="11" fill={p.light} opacity="0.5" />}
    <circle cx="50" cy="58" r="29" fill="none" stroke={p.dark} strokeWidth="1.5" opacity="0.5" />
  </g>
)

const SHAPES = {
  round: Round, oval: Oval, pear: Pear, strawberry: Strawberry, berry: Berry,
  banana: Banana, star: Star, pineapple: Pineapple, spiky: Spiky, dragon: Dragon,
  pomegranate: Pomegranate,
}

// ————— Détails partagés —————

const Stem = ({ color = '#3aa76d', long = false, small = false }) => (
  <path d={long ? 'M50 30 C52 16 58 10 62 8' : small ? 'M50 30 l3 -7' : 'M50 30 C51 22 54 20 57 18'}
        fill="none" stroke={color} strokeWidth={small ? 2.5 : 3} strokeLinecap="round" />
)

const Bumps = ({ color }) => (
  <g fill={color} opacity="0.5">
    {[[38, 46], [50, 40], [62, 46], [34, 60], [46, 56], [58, 56], [66, 62], [42, 70], [58, 70]]
      .map(([x, y], i) => <circle key={i} cx={x} cy={y} r="3" />)}
  </g>
)

const Seeds = ({ color = '#ffe08a' }) => (
  <g fill={color}>
    {[[42, 44], [58, 44], [50, 50], [36, 56], [64, 56], [44, 60], [56, 60], [50, 68], [40, 72], [60, 72]]
      .map(([x, y], i) => <ellipse key={i} cx={x} cy={y} rx="1.5" ry="2.6" />)}
  </g>
)

// Points d'un polygone en étoile (branches alternant rayon externe / interne).
function starPoints(cx, cy, outer, inner, points, startDeg = -90) {
  const out = []
  for (let i = 0; i < points * 2; i++) {
    const r = i % 2 === 0 ? outer : inner
    const a = (Math.PI / points) * i + (startDeg * Math.PI) / 180
    out.push(`${(cx + r * Math.cos(a)).toFixed(1)},${(cy + r * Math.sin(a)).toFixed(1)}`)
  }
  return out.join(' ')
}
