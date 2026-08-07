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

// Palme, vue de face : le chausson en haut, la voilure qui s'évase vers le bas. Elle passe
// par <Pair /> comme les chaussures — même moule, donc même ancre et même garantie de ne
// jamais être dupliquée.
const Fin = ({ x, body, foot, rib }) => (
  <g transform={`translate(${x} 0)`}>
    <path d="M-12 52 q12 -4 24 0 l7 30 q-19 7 -38 0 z" fill={body} />
    <g stroke={rib} strokeWidth="1.8" opacity=".55">
      <path d="M-6 58 l-4 22 M0 57 l0 23 M6 58 l4 22" />
    </g>
    <path d="M-13 40 h26 q3 0 3 5 v9 q-16 -5 -32 0 v-9 q0 -5 3 -5 z" fill={foot} />
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

// Casque audio. 🎧 est un casque VU DE FACE, posé à plat : sur une tête de fruit il faisait
// une masse noire qui avalait le crâne. Dessiné, l'arceau passe SUR la silhouette et les
// écouteurs tombent au niveau des oreilles (d'où sa `bite` de 26, plus profonde qu'un chapeau).
// ⚠️ Le dessin est LARGE ET PLAT (il n'occupe que 30→84 en hauteur) : un casque plus haut
// que large, mis à l'échelle pour que ses écouteurs atteignent les oreilles, aurait débordé
// d'un demi-fruit au-dessus du crâne. Vérifié au rendu, pas à l'œil.
const Headphones = () => (
  <g>
    <path d="M6 74 A44 44 0 0 1 94 74" fill="none" stroke="#2b303c" strokeWidth="13" strokeLinecap="round" />
    <path d="M6 74 A44 44 0 0 1 94 74" fill="none" stroke="#5b6577" strokeWidth="5" strokeLinecap="round" />
    <rect x="0" y="58" width="24" height="26" rx="11" fill="#2b303c" />
    <rect x="76" y="58" width="24" height="26" rx="11" fill="#2b303c" />
    <rect x="5" y="64" width="13" height="15" rx="6" fill="#98a2b3" />
    <rect x="82" y="64" width="13" height="15" rx="6" fill="#98a2b3" />
  </g>
)

// Serviette éponge autour du cou. Le débardeur 🎽 était une TENUE, et l'avatar est une tête :
// une serviette dit le coureur du dimanche sans lui inventer un corps.
// Les deux pans d'abord, le col PAR-DESSUS : c'est ce qui donne l'impression que la
// serviette passe derrière la nuque. Pans volontairement courts (ils s'arrêtent à 78) —
// plus longs, ils sortaient du cadre au lieu de pendre.
const Towel = () => (
  <g>
    <path d="M24 50 L46 53 L44 78 L22 74 Z" fill="#eaf0fa" stroke="#cfd8e8" strokeWidth="2" />
    <path d="M54 53 L76 50 L78 74 L56 78 Z" fill="#eaf0fa" stroke="#cfd8e8" strokeWidth="2" />
    <path d="M23 58 L45 61 L44.6 68 L22.6 65 Z" fill="#ff7a59" />
    <path d="M55 61 L77 58 L77.4 65 L55.4 68 Z" fill="#5b8def" />
    <path d="M6 34 Q50 12 94 34 L94 52 Q50 30 6 52 Z" fill="#f4f7fd" stroke="#cfd8e8" strokeWidth="2" />
  </g>
)

// Bonnet de bain : il épouse le crâne, donc `fit` ~1 (voir sizeOf). Le liseré suit la
// courbure plutôt que d'être droit — c'est ce qui fait qu'il se lit comme moulé sur la tête.
const SwimCap = ({ body = '#1f7fd1', stripe = '#ffffff' }) => (
  <g>
    <path d="M4 96 Q4 32 50 32 Q96 32 96 96 Q50 76 4 96 Z" fill={body} />
    <path d="M16 56 Q50 43 84 56" fill="none" stroke={stripe} strokeWidth="7" strokeLinecap="round" opacity=".85" />
  </g>
)

// Masque + tuba. La vitre est TRANSLUCIDE : un masque opaque effaçait le visage, alors que
// c'est le regard derrière la vitre qui fait tout le charme de la pièce.
const DiveMask = () => (
  <g>
    <path d="M92 70 L92 20 q0 -9 -9 -9" fill="none" stroke="#f2b100" strokeWidth="9" strokeLinecap="round" />
    <rect x="83" y="8" width="12" height="9" rx="4" fill="#e8863a" />
    <rect x="2" y="44" width="96" height="10" rx="5" fill="#1f2a44" />
    <rect x="17" y="29" width="66" height="38" rx="14" fill="#8fd8ff" opacity="0.4" />
    <rect x="12" y="24" width="76" height="48" rx="17" fill="none" stroke="#1f2a44" strokeWidth="9" />
    <path d="M25 38 q11 -5 22 0" stroke="#ffffff" strokeWidth="4" strokeLinecap="round" fill="none" opacity="0.7" />
  </g>
)

// Manomètre au bout de son flexible.
// ⚠️ C'était une bouée de sauvetage, et c'était impossible : un anneau assez large pour
// entourer le corps a un diamètre de ~50 unités, donc son haut remonte à la ligne des yeux
// quel que soit l'endroit où on l'accroche. Même erreur de catégorie que le débardeur — le
// cou d'un avatar-tête est une petite zone où une pièce PEND, elle n'entoure rien.
const DiveGauge = () => (
  <g>
    <path d="M58 4 q-20 24 -8 48" fill="none" stroke="#1f2a44" strokeWidth="11" strokeLinecap="round" />
    <circle cx="50" cy="72" r="25" fill="#1f2a44" />
    <circle cx="50" cy="72" r="17" fill="#f4f7fd" />
    <path d="M50 72 L61 62" stroke="#e23b54" strokeWidth="4" strokeLinecap="round" />
    <circle cx="50" cy="72" r="3" fill="#1f2a44" />
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

// Téléphone en brassard, sur UN bras (`single`) : 📱 seul flottait comme un objet posé là,
// alors que ce qu'on porte, ce sont les sangles. Elles passent donc DERRIÈRE l'appareil.
const ArmBand = () => (
  <g>
    <rect x="14" y="30" width="72" height="13" rx="6" fill="#c6f24a" />
    <rect x="14" y="58" width="72" height="13" rx="6" fill="#c6f24a" />
    <rect x="27" y="16" width="46" height="68" rx="10" fill="#2b303c" />
    <rect x="33" y="24" width="34" height="46" rx="4" fill="#7fd4ff" />
    <rect x="33" y="24" width="34" height="15" rx="4" fill="#bde9ff" />
    <circle cx="50" cy="77" r="3.2" fill="#8d97a8" />
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
  // Les mêmes baskets, mais délavées : gris terne, semelle jaunie, lacets fanés. Tout le
  // dessin est déjà paramétré — une panoplie « usée » ne coûte donc que quatre couleurs.
  worn_sneakers: { view: '8 38 84 42', pair: true,
    node: <Pair body="#9aa3ad" sole="#e6e0cf" tongue="#c3c9d1" lace="#d8d2c0" /> },
  trail: { view: '8 33 84 47', pair: true, node: <Pair body="#8a5a2b" sole="#3f2d1c" tongue="#c98a4b" lace="#f6c945" shaft={7} /> },
  ballet: { view: '8 40 84 36', pair: true, node: <Pair as={Flat} body="#ff9fc0" sole="#e6749b" trim="#ffd6e5" /> },
  skates: { view: '8 33 84 47', pair: true, node: <Pair as={Skate} body="#f2b100" sole="#fff3cc" tongue="#ffe08a" wheel="#4a4360" /> },
  boots7: { view: '8 25 84 55', pair: true, node: <Pair body="#6c5ce7" sole="#f6c945" tongue="#a99bff" lace="#f6c945" shaft={15} /> },
  maracas: { view: '9 9 82 85', em: 0.3, node: <Maracas /> },
  paw: { view: '18 20 66 60', em: 0.3, node: <Paw color="#6c5ce7" pad="#a99bff" /> },
  wand: { single: true, em: 0.28, emoji: '🪄' },
  // ⚠️ `fit` au lieu de `em` = la pièce épouse la TÊTE (voir sizeOf dans FruitAvatar) : sa
  // largeur est un multiple de celle du fruit. Réservé aux pièces LARGES — celles dont on
  // voit tout de suite qu'elles dépassent quand la tête est étroite. Les valeurs sont
  // calées pour redonner la taille d'aujourd'hui sur un fruit rond (demi-largeur 30), celui
  // sur lequel chaque dessin avait été réglé : seuls les fruits étroits changent.
  gold_hat: { view: '12 16 76 64', fit: 0.77, node: <GoldHat /> },
  eyepatch: { view: '0 20 100 50', em: 0.34, node: <EyePatch /> },
  visor: { view: '2 29 96 39', fit: 0.57, node: <Visor /> },
  bib: { view: '17 22 66 57', em: 0.26, node: <Bib /> },
  bandana: { view: '10 26 80 62', fit: 0.5, node: <Bandana /> },
  mitten: { view: '22 24 66 60', em: 0.32, node: <Mitten body="#5f8cbb" cuff="#ff7a59" thumb="#41668f" /> },
  // `bite` : les écouteurs doivent tomber au niveau des oreilles, bien plus bas que le bord
  // d'un chapeau — c'est tout l'intérêt d'un réglage PAR PIÈCE (voir FruitAvatar).
  // 1.1 : les écouteurs se posent SUR les côtés de la tête, ils doivent donc la dépasser
  // un peu. Plancher relevé à .38 — en dessous on ne reconnaît plus un casque.
  headphones: { view: '0 26 100 62', fit: 1.1, minEm: 0.38, bite: 40, node: <Headphones /> },
  armband: { view: '12 12 76 76', em: 0.26, single: true, node: <ArmBand /> },
  towel: { view: '4 10 92 72', fit: 0.83, bite: 29, node: <Towel /> },
  // — Panoplie du plongeur —
  flippers: { view: '8 36 84 50', pair: true, node: <Pair as={Fin} body="#1f9ecb" foot="#0f6f92" rib="#0b5a78" /> },
  swim_cap: { view: '2 28 96 70', fit: 1.05, node: <SwimCap /> },
  dive_mask: { view: '0 4 100 72', fit: 0.9, node: <DiveMask /> },
  // Taille FIXE, sans `fit` : un objet qui pend au bout d'un flexible n'a pas de raison de
  // grossir avec la tête, contrairement à ce qui se pose dessus.
  dive_gauge: { view: '22 0 56 100', em: 0.3, node: <DiveGauge /> },
  // 🔦 est une lampe vue de biais : reflétée, elle en faisait deux. `single` la garde d'un
  // seul côté, comme la baguette magique — et l'emoji suffit, inutile de la dessiner.
  dive_light: { single: true, em: 0.28, emoji: '🔦' },
  bowtie: { view: '10 24 80 52', em: 0.26, node: <BowTie /> },
  cowboy_hat: { view: '8 30 84 52', fit: 0.77, node: <CowboyHat /> },
  santa_hat: { view: '18 22 79 62', fit: 0.77, node: <SantaHat /> },
  bucket_hat: { view: '10 34 80 48', fit: 0.73, node: <BucketHat /> },
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
