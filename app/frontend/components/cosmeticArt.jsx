// Cosmétiques dessinés en SVG, pour les pièces que l'emoji rate.
//
// Le catalogue reste **emoji par défaut** : ajouter une pièce, c'est une ligne dans le seed.
// Mais deux familles d'emojis ne marchent pas sur un avatar-fruit :
//   1. les chaussures — 👟 🥾 🛼 sont des godasses UNIQUES vues de PROFIL ; on veut une
//      paire vue de face, comme deux pieds sous le fruit ;
//   2. les visages entiers — 🤠 🧐 🎅 collent une deuxième tête sur celle du fruit.
// Ces pièces portent une clé `cosmetics.art` et sont dessinées ici, à plat, dans la charte.
//
// Une entrée = { em, pair, view, node } : `em` la taille relative à l'avatar (les paires
// sont larges, donc plus grandes qu'un emoji), `node` le contenu d'un viewBox 0 0 100 100
// centré, `pair` quand le dessin contient DÉJÀ les deux pièces (jamais dupliqué alors),
// `view` le recadrage de la vignette de catalogue.

// ————— Chaussures, vues de face —————

// Une chaussure de face : semelle + tige + languette + lacets croisés. Volontairement
// TRAPUE (plus large que haute) — vue de face, un pied se lit à l'horizontale ; une forme
// élancée donnait des jambes montant jusqu'au milieu du fruit.
const Shoe = ({ x, body, sole, tongue, lace = '#ffffff', shaft = 0 }) => (
  <g transform={`translate(${x} 0)`}>
    {shaft > 0 && <rect x="-14" y={44 - shaft} width="28" height={shaft + 4} rx="4" fill={body} />}
    <path d="M-17 66 v-11 q0 -13 17 -13 q17 0 17 13 v11 z" fill={body} />
    <path d="M-7 66 v-13 q0 -7 7 -7 q7 0 7 7 v13 z" fill={tongue} />
    <g stroke={lace} strokeWidth="2.6" strokeLinecap="round">
      <path d="M-8 52 L8 57 M8 52 L-8 57" />
    </g>
    <rect x="-19" y="63" width="38" height="13" rx="6" fill={sole} />
  </g>
)

// Une PAIRE : le pied gauche et le pied droit, vus de face, sous le fruit.
const Pair = ({ as: One = Shoe, ...props }) => (
  <>
    <One {...props} x={29} />
    <One {...props} x={71} />
  </>
)

// Ballerine : pas de lacets, un décolleté et un petit nœud.
const Flat = ({ x, body, sole, trim }) => (
  <g transform={`translate(${x} 0)`}>
    <path d="M-17 66 v-10 q0 -12 17 -12 q17 0 17 12 v10 z" fill={body} />
    <ellipse cx="0" cy="47" rx="8" ry="5" fill={trim} />
    <path d="M-6 42 l6 3 l-6 3 z M6 42 l-6 3 l6 3 z" fill={trim} />
    <rect x="-19" y="63" width="38" height="11" rx="5" fill={sole} />
  </g>
)

// Roller : la tige d'une basket posée sur une platine à trois roues.
const Skate = ({ x, body, sole, tongue, wheel }) => (
  <g transform={`translate(${x} 0)`}>
    <path d="M-16 58 v-9 q0 -12 16 -12 q16 0 16 12 v9 z" fill={body} />
    <path d="M-6 58 v-11 q0 -6 6 -6 q6 0 6 6 v11 z" fill={tongue} />
    <rect x="-18" y="56" width="36" height="9" rx="4" fill={sole} />
    <g fill={wheel}>
      <circle cx="-10" cy="70" r="6" />
      <circle cx="0" cy="70" r="6" />
      <circle cx="10" cy="70" r="6" />
    </g>
  </g>
)

// ————— Chapeaux (brim autour de y=72, la ligne du crâne du fruit) —————

// Haut-de-forme DORÉ : 🎩 est noir et bleu, le nom promettait de l'or.
const GoldHat = () => (
  <g>
    <path d="M33 70 V26 q0 -7 17 -7 q17 0 17 7 V70 z" fill="#f6c945" />
    <ellipse cx="50" cy="26" rx="17" ry="5.5" fill="#ffe08a" />
    <rect x="32" y="53" width="36" height="10" rx="2" fill="#8a6d1b" />
    <ellipse cx="50" cy="71" rx="36" ry="8" fill="#c9930a" />
    <ellipse cx="50" cy="69" rx="36" ry="8" fill="#f6c945" />
  </g>
)

const CowboyHat = () => (
  <g>
    <path d="M12 72 q38 -14 76 0 q-38 12 -76 0 z" fill="#a9743f" />
    <path d="M30 70 q-4 -30 6 -36 q6 6 14 6 q8 0 14 -6 q10 6 6 36 z" fill="#c98a4b" />
    <rect x="29" y="60" width="42" height="8" rx="3" fill="#5c3a1c" />
    <circle cx="50" cy="64" r="3.4" fill="#f6c945" />
  </g>
)

const SantaHat = () => (
  <g>
    <path d="M26 66 q0 -34 26 -40 q22 -4 30 20 q-14 4 -22 20 z" fill="#e23b54" />
    <rect x="22" y="62" width="58" height="14" rx="7" fill="#fff" />
    <circle cx="84" cy="46" r="9" fill="#fff" />
  </g>
)

const BucketHat = () => (
  <g>
    <path d="M14 68 q36 16 72 0 q-6 10 -36 10 q-30 0 -36 -10 z" fill="#3f8fd0" />
    <path d="M28 70 q-3 -32 22 -32 q25 0 22 32 z" fill="#4fa3e8" />
    <rect x="27" y="60" width="46" height="7" rx="3" fill="#2c6ea6" />
  </g>
)

// ————— Gants —————

// Une patte, UNE seule : 🐾 est déjà une paire d'empreintes, reflété il en faisait quatre.
const Paw = ({ color, pad }) => (
  <g fill={color}>
    <ellipse cx="50" cy="62" rx="21" ry="16" />
    <ellipse cx="29" cy="41" rx="8" ry="10.5" />
    <ellipse cx="43" cy="32" rx="8" ry="11.5" />
    <ellipse cx="57" cy="32" rx="8" ry="11.5" />
    <ellipse cx="71" cy="41" rx="8" ry="10.5" />
    <ellipse cx="50" cy="62" rx="11" ry="8" fill={pad} />
  </g>
)

// Une moufle, UNE seule main : le slot `hands` la reflète de chaque côté. L'emoji 🧤
// représente déjà une paire — reflété, il donnait quatre mains.
const Mitten = ({ body, cuff, thumb }) => (
  <g>
    <rect x="26" y="44" width="20" height="24" rx="10" fill={thumb} />
    <rect x="38" y="28" width="42" height="42" rx="18" fill={body} />
    <rect x="32" y="64" width="52" height="16" rx="8" fill={cuff} />
  </g>
)

// ————— Accessoires —————

// Maracas croisées. 🪇 n'existe qu'en Unicode 15 (2022) : carré vide sur les vieux
// Android et les vieux Windows — une pièce payante ne peut pas se permettre ça.
const Maracas = () => (
  <g>
    <g stroke="#8a5a2b" strokeWidth="8" strokeLinecap="round">
      <path d="M36 46 L62 88" />
      <path d="M64 46 L38 88" />
    </g>
    <ellipse cx="32" cy="34" rx="19" ry="21" fill="#f2b100" />
    <ellipse cx="68" cy="34" rx="19" ry="21" fill="#e23b54" />
    <g fill="#ffffff" opacity="0.5">
      <ellipse cx="26" cy="26" rx="5" ry="3.5" />
      <ellipse cx="62" cy="26" rx="5" ry="3.5" />
    </g>
    <g fill="#8a6d1b"><circle cx="26" cy="42" r="3" /><circle cx="38" cy="38" r="3" /></g>
    <g fill="#8e1122"><circle cx="62" cy="42" r="3" /><circle cx="74" cy="38" r="3" /></g>
  </g>
)

// ————— Cou —————

// Dossard : le numéro de course, en aplats (pas de texte, illisible en vignette).
const Bib = () => (
  <g>
    <rect x="21" y="26" width="58" height="49" rx="6" fill="#ffffff" stroke="#d6cfe4" strokeWidth="2.5" />
    <rect x="28" y="33" width="44" height="8" rx="3" fill="#ff7a59" />
    <g fill="#252333">
      <rect x="30" y="47" width="9" height="19" rx="2" />
      <rect x="45" y="47" width="9" height="19" rx="2" />
      <rect x="60" y="47" width="9" height="19" rx="2" />
    </g>
  </g>
)

// Bandana noué autour du cou.
const Bandana = () => (
  <g>
    <path d="M14 32 Q50 47 86 32 L50 84 Z" fill="#f0325b" />
    <path d="M14 32 Q50 47 86 32" stroke="#c81e45" strokeWidth="6" fill="none" strokeLinecap="round" />
    <circle cx="50" cy="43" r="6" fill="#c81e45" />
  </g>
)


// Nœud papillon : 🎀 servait déjà de bandeau, deux pièces au même glyphe se confondaient.
const BowTie = () => (
  <g>
    <path d="M46 40 L14 28 v44 L46 60 z" fill="#f0325b" />
    <path d="M54 40 L86 28 v44 L54 60 z" fill="#f0325b" />
    <rect x="41" y="38" width="18" height="24" rx="6" fill="#c81e45" />
  </g>
)

// ————— Lunettes (le verre tombe sur l'œil, à droite de la boîte) —————

// Cache-œil : la lanière traverse, la pièce couvre l'œil droit du fruit.
const EyePatch = () => (
  <g>
    <path d="M2 32 Q50 22 98 38" stroke="#2b2333" strokeWidth="5" fill="none" strokeLinecap="round" />
    <path d="M60 34 h38 v20 a19 16 0 0 1 -38 0 z" fill="#2b2333" />
    <path d="M66 42 h26" stroke="#5b5470" strokeWidth="3" strokeLinecap="round" />
  </g>
)

// Visière : un bandeau plein sur les deux yeux, verre menthe.
const Visor = () => (
  <g>
    <rect x="5" y="33" width="90" height="31" rx="15" fill="#2b2333" />
    <rect x="12" y="40" width="76" height="16" rx="8" fill="#2fd6a3" />
    <rect x="18" y="43" width="22" height="5" rx="2.5" fill="#eafff7" opacity="0.7" />
  </g>
)


// Monocle : le verre tombe sur l'œil DROIT du fruit (à droite de la boîte), chaînette en
// contrebas. L'emoji 🧐 est un visage entier — il aurait collé une tête sur la tête.
const Monocle = () => (
  <g>
    <circle cx="76" cy="46" r="21" fill="#cfe6ff" fillOpacity="0.5" stroke="#3a3050" strokeWidth="5" />
    <path d="M68 33 q8 -4 15 2" stroke="#fff" strokeWidth="4" strokeLinecap="round" fill="none" />
    <path d="M92 60 q6 16 0 32" stroke="#f2b100" strokeWidth="4" strokeLinecap="round" fill="none"
          strokeDasharray="1 7" />
  </g>
)

// `pair: true` = le dessin contient DÉJÀ les deux pièces (les chaussures), il n'est donc
// jamais dupliqué. Sans ce drapeau, une pièce d'un slot symétrique (les gants) est posée
// de chaque côté, la droite en miroir.
//
// `view` = un viewBox RECADRÉ sur le dessin, utilisé par la vignette (armoire, boutique) :
// sur l'avatar la pièce occupe une petite zone d'un carré de 100, mais dans une case de
// catalogue elle doit remplir la case comme le fait un emoji.
// `single: true` = la pièce ne se porte QUE d'un côté (une baguette se tient d'une main) :
// le slot symétrique la pose une seule fois, à droite, sans miroir.
//
// Une entrée peut aussi porter `emoji` au lieu de `node` : le glyphe est alors rendu tel
// quel, mais avec les drapeaux de mise en page ci-dessus — c'est ce qui permet de dire
// « cet emoji-là ne se duplique pas » sans le dessiner.
export const COSMETIC_ART = {
  sneakers: { view: '8 38 84 42', pair: true, node: <Pair body="#ff7a59" sole="#ffffff" tongue="#ffb59f" /> },
  trail: { view: '8 33 84 47', pair: true, node: <Pair body="#8a5a2b" sole="#3f2d1c" tongue="#c98a4b" lace="#f6c945" shaft={7} /> },
  ballet: { view: '8 40 84 36', pair: true, node: <Pair as={Flat} body="#ff9fc0" sole="#e6749b" trim="#ffd6e5" /> },
  skates: { view: '8 33 84 47', pair: true, node: <Pair as={Skate} body="#f2b100" sole="#fff3cc" tongue="#ffe08a" wheel="#4a4360" /> },
  boots7: { view: '8 25 84 55', pair: true, node: <Pair body="#6c5ce7" sole="#f6c945" tongue="#a99bff" lace="#f6c945" shaft={15} /> },
  maracas: { view: '9 9 82 85', em: 0.3, node: <Maracas /> },
  paw: { view: '18 20 66 60', em: 0.3, node: <Paw color="#6c5ce7" pad="#a99bff" /> },
  wand: { single: true, em: 0.28, emoji: '🪄' },
  gold_hat: { view: '12 16 76 64', em: 0.46, node: <GoldHat /> },
  eyepatch: { view: '0 20 100 50', em: 0.34, node: <EyePatch /> },
  visor: { view: '2 29 96 39', em: 0.34, node: <Visor /> },
  bib: { view: '17 22 66 57', em: 0.26, node: <Bib /> },
  bandana: { view: '10 26 80 62', em: 0.3, node: <Bandana /> },
  mitten: { view: '22 24 66 60', em: 0.32, node: <Mitten body="#5f8cbb" cuff="#ff7a59" thumb="#41668f" /> },
  bowtie: { view: '10 24 80 52', em: 0.26, node: <BowTie /> },
  cowboy_hat: { view: '8 30 84 52', em: 0.46, node: <CowboyHat /> },
  santa_hat: { view: '18 22 79 62', em: 0.46, node: <SantaHat /> },
  bucket_hat: { view: '10 34 80 48', em: 0.44, node: <BucketHat /> },
  monocle: { view: '51 21 50 75', em: 0.44, node: <Monocle /> },
}

export const artFor = (key) => (key ? COSMETIC_ART[key] : null)

// Vignette d'un cosmétique (armoire, boutique) : le dessin s'il y en a un, sinon l'emoji.
export function CosmeticIcon({ art, emoji, className = '', style }) {
  const drawn = artFor(art)
  if (!drawn?.node) return <span className={className} style={style}>{drawn?.emoji || emoji || '🎁'}</span>
  return (
    <span className={className} style={style}>
      <svg viewBox={drawn.view || '0 0 100 100'} className="cos-art" role="presentation">{drawn.node}</svg>
    </span>
  )
}
