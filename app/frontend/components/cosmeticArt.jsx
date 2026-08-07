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

// Haut-de-forme. Le doré d'abord (🎩 est noir et bleu, le nom promettait de l'or), puis
// paramétré : le chapeau de lutin n'est qu'un jeu de couleurs et une boucle en plus.
const TopHat = ({ body, top, band, brim, buckle }) => (
  <g>
    <path d="M33 70 V26 q0 -7 17 -7 q17 0 17 7 V70 z" fill={body} />
    <ellipse cx="50" cy="26" rx="17" ry="5.5" fill={top} />
    <rect x="32" y={buckle ? 51 : 53} width="36" height={buckle ? 13 : 10} rx="2" fill={band} />
    {buckle && <rect x="43" y="52" width="14" height="11" rx="2" fill="none" stroke={buckle} strokeWidth="3.5" />}
    <ellipse cx="50" cy="71" rx="36" ry="8" fill={brim} />
    <ellipse cx="50" cy="69" rx="36" ry="8" fill={body} />
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

// Ceinture de plomb : une sangle et ses plombs enfilés dessus, boucle dorée au milieu.
// ⚠️ Une BANDE, pas un anneau. Une bouée de sauvetage a été dessinée ici puis jetée : un
// anneau assez large pour entourer le corps a un diamètre de ~50 unités, donc son haut
// remonte à la ligne des yeux quel que soit l'endroit où on l'accroche. Une ceinture ne se
// referme pas derrière — elle suit la base du fruit et s'arrête là.
// ⚠️ Les plombs sont plus COURTS que la sangle et espacés : à hauteur égale et collés, ils
// la masquaient entièrement et l'ensemble devenait un bloc gris.
const WeightBelt = () => (
  <g>
    <path d="M4 30 Q50 52 96 30 L96 56 Q50 78 4 56 Z" fill="#2b3240" stroke="#1b2029" strokeWidth="2" />
    <g fill="#9aa2b0" stroke="#5c6473" strokeWidth="2">
      <rect x="8" y="28" width="14" height="30" rx="3" />
      <rect x="27" y="34" width="14" height="30" rx="3" />
      <rect x="59" y="34" width="14" height="30" rx="3" />
      <rect x="78" y="28" width="14" height="30" rx="3" />
    </g>
    <rect x="44" y="38" width="12" height="30" rx="3" fill="#c9a227" stroke="#8d6f13" strokeWidth="2" />
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

// Les bras d'une combinaison : harpon dans une main, lampe torche dans l'autre.
//
// ⚠️ `pair: true` — le dessin contient DÉJÀ les deux bras, il n'est donc jamais dupliqué.
// C'est ce qui permet de leur donner des mains DIFFÉRENTES : un slot symétrique reflète la
// même pièce, il ne sait faire que deux fois la même chose.
// ⚠️ `back: true` — la pièce passe DERRIÈRE le fruit. C'est ce qui rend les bras crédibles :
// les épaules partent d'un point caché par la silhouette et seuls les avant-bras ressortent,
// donc un fruit étroit en montre plus qu'un large, sans un seul calcul. Devant, il fallait
// laisser un trou au milieu du dessin et il barrait quand même le visage.
// ⚠️ Le harpon est VERTICAL : penché, son fût passait derrière le fruit et disparaissait.
const WetsuitArms = () => (
  <g>
    <path d="M13 90 L13 30" stroke="#aeb9c9" strokeWidth="4" strokeLinecap="round" />
    <path d="M13 24 l-6 11 h12 z" fill="#8d99ab" />
    <path d="M7 44 l6 -7 l6 7" fill="none" stroke="#8d99ab" strokeWidth="2.6" strokeLinejoin="round" />
    <rect x="5" y="55" width="16" height="20" rx="4" fill="#3d4757" />
    <rect x="5" y="59" width="16" height="4.5" fill="#1f9ecb" />
    <path d="M44 44 L26 58 L14 78" fill="none" stroke="#17233a" strokeWidth="13"
          strokeLinecap="round" strokeLinejoin="round" />
    <path d="M20 68 L15 76" fill="none" stroke="#1f9ecb" strokeWidth="13" strokeLinecap="round" />
    <circle cx="13" cy="80" r="9" fill="#0d1626" />
    <path d="M56 44 L74 58 L86 78" fill="none" stroke="#17233a" strokeWidth="13"
          strokeLinecap="round" strokeLinejoin="round" />
    <path d="M80 68 L85 76" fill="none" stroke="#1f9ecb" strokeWidth="13" strokeLinecap="round" />
    <circle cx="87" cy="80" r="9" fill="#0d1626" />
    <path d="M100 58 L100 92 L88 84 L88 70 Z" fill="#f2b100" opacity="0.32" />
    <rect x="78" y="70" width="13" height="11" rx="3" fill="#2b303c" />
    <rect x="89" y="69" width="5" height="13" rx="2" fill="#ffd97a" />
  </g>
)

// ————— Panoplie du loup —————

// Oreilles de loup, ÉCARTÉES : elles se rejoignaient au milieu du crâne et faisaient un
// bonnet à pointes plutôt que deux oreilles. Un creux entre les deux, et la silhouette du
// fruit (les palmes de l'ananas, la queue d'une cerise) passe au travers.
// Comme le bonnet de bain, le dessin REMPLIT le bas de sa boîte : c'est le bord de la BOÎTE
// qui se pose sur le crâne, pas celui du dessin.
const WolfEars = ({ fur = '#6b6f7a', dark = '#4a4f59', inner = '#e79aa8' }) => (
  <g>
    <path d="M4 98 L13 24 L42 86 Z" fill={fur} stroke={dark} strokeWidth="3" strokeLinejoin="round" />
    <path d="M18 82 L21 44 L34 84 Z" fill={inner} />
    <path d="M96 98 L87 24 L58 86 Z" fill={fur} stroke={dark} strokeWidth="3" strokeLinejoin="round" />
    <path d="M82 82 L79 44 L66 84 Z" fill={inner} />
  </g>
)

// Balafre. ⚠️ Taille FIXE et non `fit` : le visage est le même sur tous les fruits (ligne des
// yeux commune), donc une cicatrice n'a aucune raison de grandir avec la silhouette.
// Elle passe SUR LA TEMPE, à gauche de l'œil : centrée, elle effaçait l'œil au lieu de le barrer.
// ⚠️ Pour la rétrécir, on rétrécit le DESSIN dans sa boîte et pas `em` : la pièce est centrée
// sur son ancre, donc réduire la boîte l'aurait ramenée sur l'œil au lieu de la laisser sur
// la tempe. Le décalage vient de la position du tracé dans la boîte — lui seul le tient.
const Scar = () => (
  <g stroke="#b5514f" strokeLinecap="round" fill="none">
    <path d="M18.5 28 L22.5 72" strokeWidth="2.6" />
    <g strokeWidth="1.8">
      <path d="M14.5 37 L26.5 35.5 M13.5 49 L27.5 47.5 M15.5 61 L28.5 59.5" />
    </g>
  </g>
)

// Collier à pointes : les pointes d'abord, le collier PAR-DESSUS — elles doivent sortir de
// dessous, pas flotter à côté.
const SpikedCollar = () => (
  <g>
    <g fill="#2f2622">
      <path d="M13 42 l6 15 l6 -15 z" /><path d="M31 46 l6 16 l6 -16 z" />
      <path d="M51 46 l6 16 l6 -16 z" /><path d="M69 42 l6 15 l6 -15 z" />
    </g>
    <path d="M6 24 Q50 10 94 24 L94 46 Q50 32 6 46 Z" fill="#4a3a32" stroke="#241c19" strokeWidth="2.5" />
    <circle cx="50" cy="52" r="10" fill="#c9a227" stroke="#8d6f13" strokeWidth="2" />
  </g>
)

// Un coussinet, vu de face : la grosse pelote en bas, les quatre doigts au-dessus. Passe par
// <Pair /> comme les chaussures et les palmes.
const PawFoot = ({ x, fur, pad }) => (
  <g transform={`translate(${x} 0)`}>
    <ellipse cx="0" cy="68" rx="18" ry="13" fill={fur} />
    <ellipse cx="0" cy="70" rx="9" ry="7" fill={pad} />
    <circle cx="-12" cy="54" r="5" fill={fur} />
    <circle cx="-4" cy="49" r="5" fill={fur} />
    <circle cx="4" cy="49" r="5" fill={fur} />
    <circle cx="12" cy="54" r="5" fill={fur} />
  </g>
)

// ————— Panoplie de Noël —————

// Bois de renne. Écartés comme les oreilles de loup, et bottom-flush : c'est le bord de la
// BOÎTE qui se pose sur le crâne, pas celui du dessin.
const Antlers = ({ horn = '#8a5a2b' }) => (
  <g fill="none" stroke={horn} strokeWidth="7" strokeLinecap="round" strokeLinejoin="round">
    <path d="M36 98 L26 60 L16 32" /><path d="M27 66 L8 50" /><path d="M22 44 L36 32" />
    <path d="M64 98 L74 60 L84 32" /><path d="M73 66 L92 50" /><path d="M78 44 L64 32" />
  </g>
)

// Lunettes du Père Noël : la babiole de fête — verres fumés, monture rouge, bonnet posé
// dessus et branches en sucre d'orge.
// ⚠️ Verres OPAQUES, contrairement au masque de plongée et aux lunettes de ski : ici le
// verre teinté EST la pièce. Le reflet en diagonale évite qu'ils fassent deux trous noirs.
// ⚠️ Le bonnet monte jusqu'au crâne : cette pièce se dispute donc l'espace avec ce qu'on
// porte au chapeau (les bois de renne de la même panoplie n'en laissent rien voir).
const SantaGlasses = () => (
  <g>
    <g fill="#f4f7fd">
      <rect x="0" y="43" width="17" height="9" rx="3" /><rect x="83" y="43" width="17" height="9" rx="3" />
    </g>
    <g fill="#c0182f">
      <path d="M0 43 h5 l-5 9 z" /><path d="M7 43 h5 l-5 9 z" /><path d="M14 43 h3 l-3 9 z" />
      <path d="M100 43 h-5 l5 9 z" /><path d="M93 43 h-5 l5 9 z" /><path d="M86 43 h-3 l3 9 z" />
    </g>
    <path d="M16 28 Q22 2 58 2 Q84 3 90 20 L90 28 Z" fill="#c0182f" />
    <circle cx="92" cy="12" r="11" fill="#f4f7fd" />
    <rect x="10" y="23" width="80" height="14" rx="7" fill="#f4f7fd" />
    <rect x="14" y="36" width="34" height="28" rx="8" fill="#23262e" />
    <rect x="52" y="36" width="34" height="28" rx="8" fill="#23262e" />
    <path d="M20 58 L36 40" stroke="#5b6577" strokeWidth="5" strokeLinecap="round" opacity="0.55" />
    <path d="M58 58 L74 40" stroke="#5b6577" strokeWidth="5" strokeLinecap="round" opacity="0.55" />
    <g fill="none" stroke="#c0182f" strokeWidth="5">
      <rect x="12" y="34" width="38" height="32" rx="9" /><rect x="50" y="34" width="38" height="32" rx="9" />
    </g>
    <rect x="46" y="40" width="8" height="5" fill="#c0182f" />
  </g>
)

// Guirlande lumineuse : un fil qui pend et ses ampoules posées dessus. Une BANDE, pas un
// anneau — comme la ceinture de plomb et le collier à pointes (voir CLAUDE.md).
const Bulb = ({ x, y, color }) => (
  <g fill={color}>
    <path d={`M${x} ${y - 3} l-4 4 l4 9 l4 -9 z`} />
    <circle cx={x} cy={y + 7} r="6.5" />
  </g>
)
const Garland = () => (
  <g>
    <path d="M2 24 Q50 62 98 24" fill="none" stroke="#2f5d3a" strokeWidth="5" strokeLinecap="round" />
    <Bulb x={17.8} y={35} color="#e23b54" />
    <Bulb x={31.6} y={41} color="#f2b100" />
    <Bulb x={50} y={44} color="#3aa76d" />
    <Bulb x={68.4} y={41} color="#4a7fd1" />
    <Bulb x={82.2} y={35} color="#e23b54" />
  </g>
)

// Bras de manteau et moufles. Même construction que les bras de combinaison du plongeur :
// le dessin contient les DEUX bras (`pair`) et passe DERRIÈRE le fruit (`back`), donc
// l'épaule est masquée par le corps et seul l'avant-bras ressort.
// ⚠️ Les moufles se tiennent PRÈS du corps : posées plus bas et plus au large, elles se
// lisaient comme deux pommes flottant à côté du fruit. Le revers de fourrure fait la
// jonction — sans lui, la manche verte et la moufle rouge paraissaient décollées.
const XmasArms = () => (
  <g>
    <path d="M44 44 L27 57 L16 72" fill="none" stroke="#1f5b3a" strokeWidth="14"
          strokeLinecap="round" strokeLinejoin="round" />
    <path d="M56 44 L73 57 L84 72" fill="none" stroke="#1f5b3a" strokeWidth="14"
          strokeLinecap="round" strokeLinejoin="round" />
    <ellipse cx="12" cy="80" rx="10" ry="11" fill="#c0182f" />
    <ellipse cx="3" cy="74" rx="5" ry="6" fill="#c0182f" />
    <ellipse cx="88" cy="80" rx="10" ry="11" fill="#c0182f" />
    <ellipse cx="97" cy="74" rx="5" ry="6" fill="#c0182f" />
    <ellipse cx="18" cy="70" rx="9" ry="6" fill="#f4f7fd" transform="rotate(-42 18 70)" />
    <ellipse cx="82" cy="70" rx="9" ry="6" fill="#f4f7fd" transform="rotate(42 82 70)" />
  </g>
)

// ————— Panoplie du Père Noël —————

// La grande barbe. ⚠️ Dans le slot des LUNETTES, mais dessinée BAS dans sa boîte : c'est la
// même ruse que la balafre — le décalage ne tient qu'à la position du tracé, la pièce étant
// centrée sur la ligne des yeux. La moustache s'arrête au-dessus de la bouche et la barbe
// reprend en dessous : d'un seul bloc, elle effaçait le sourire.
const Beard = ({ hair = '#f4f7fd', shade = '#d3dbe6' }) => (
  <g fill={hair} stroke={shade} strokeWidth="2" strokeLinejoin="round">
    <path d="M20 70 Q18 98 50 100 Q82 98 80 70 Q72 80 50 80 Q28 80 20 70 Z" />
    <path d="M50 60 Q40 51 29 55 Q21 59 26 66 Q37 71 50 63 Z" />
    <path d="M50 60 Q60 51 71 55 Q79 59 74 66 Q63 71 50 63 Z" />
  </g>
)

// Bras chargés de cadeaux : manches rouges à revers de fourrure, un paquet dans chaque main.
// Même construction que les bras du plongeur et de Noël (`pair` + `back`).
const Gift = ({ x, wrap, ribbon }) => (
  <g>
    <rect x={x - 13} y="70" width="26" height="24" rx="3" fill={wrap} />
    <rect x={x - 3} y="70" width="6" height="24" fill={ribbon} />
    <rect x={x - 13} y="79" width="26" height="5" fill={ribbon} />
    <path d={`M${x} 70 q-9 -9 -1 -9 q4 0 1 9 z M${x} 70 q9 -9 1 -9 q-4 0 -1 9 z`} fill={ribbon} />
  </g>
)
const GiftArms = () => (
  <g>
    <path d="M44 42 L26 54 L15 68" fill="none" stroke="#c0182f" strokeWidth="14"
          strokeLinecap="round" strokeLinejoin="round" />
    <path d="M56 42 L74 54 L85 68" fill="none" stroke="#c0182f" strokeWidth="14"
          strokeLinecap="round" strokeLinejoin="round" />
    <ellipse cx="17" cy="66" rx="9" ry="6.5" fill="#f4f7fd" transform="rotate(-40 17 66)" />
    <ellipse cx="83" cy="66" rx="9" ry="6.5" fill="#f4f7fd" transform="rotate(40 83 66)" />
    <Gift x={14} wrap="#3aa76d" ribbon="#f2b100" />
    <Gift x={86} wrap="#4a7fd1" ribbon="#f4f7fd" />
  </g>
)

// ————— Panoplie de l'intello —————

// Chaussure cirée, vue de face : une empeigne basse et sans lacets, plus fine que la basket,
// et un reflet qui dit le cuir ciré.
const DressShoe = ({ x, body, sole, shine, buckle }) => (
  <g transform={`translate(${x} 0)`}>
    <path d="M-17 66 v-9 q0 -14 17 -14 q17 0 17 14 v9 z" fill={body} />
    <ellipse cx="-5" cy="51" rx="6.5" ry="4" fill={shine} opacity="0.45" />
    {buckle
      ? <rect x="-6" y="52" width="12" height="9" rx="2" fill="none" stroke={buckle} strokeWidth="3" />
      : <path d="M-9 60 h18" stroke={sole} strokeWidth="2.5" strokeLinecap="round" />}
    <rect x="-19" y="63" width="38" height="12" rx="5" fill={sole} />
  </g>
)

// Un livre ouvert dans une main, un verre de vin dans l'autre. Même construction que les
// bras du plongeur, de Noël et du Père Noël (`pair` + `back`) : c'est le seul moyen d'avoir
// deux mains DIFFÉRENTES, un slot symétrique ne sachant faire que deux fois la même chose.
const ScholarArms = () => (
  <g>
    <path d="M44 42 L27 53 L17 66" fill="none" stroke="#2b2f3a" strokeWidth="14"
          strokeLinecap="round" strokeLinejoin="round" />
    <path d="M56 42 L73 53 L83 66" fill="none" stroke="#2b2f3a" strokeWidth="14"
          strokeLinecap="round" strokeLinejoin="round" />
    <ellipse cx="19" cy="64" rx="8.5" ry="6" fill="#f4f7fd" transform="rotate(-42 19 64)" />
    <ellipse cx="81" cy="64" rx="8.5" ry="6" fill="#f4f7fd" transform="rotate(42 81 64)" />
    <path d="M0 78 L17 72 L17 94 L0 99 Z" fill="#f4f7fd" stroke="#c2ccdb" strokeWidth="1.6" />
    <path d="M34 78 L17 72 L17 94 L34 99 Z" fill="#f4f7fd" stroke="#c2ccdb" strokeWidth="1.6" />
    <path d="M0 78 L17 72 L17 76 L0 82 Z" fill="#7a2f3a" />
    <path d="M34 78 L17 72 L17 76 L34 82 Z" fill="#7a2f3a" />
    <g stroke="#c2ccdb" strokeWidth="1.4">
      <path d="M4 86 L14 83 M4 90 L14 87 M20 83 L30 86 M20 87 L30 90" />
    </g>
    <path d="M74 62 q0 18 11 18 q11 0 11 -18 z" fill="#dbe3ee" opacity="0.75" />
    <path d="M76 70 q1 8 9 8 q8 0 9 -8 z" fill="#8e1122" />
    <rect x="83.5" y="79" width="3" height="12" fill="#dbe3ee" />
    <ellipse cx="85" cy="92" rx="9" ry="3" fill="#dbe3ee" />
  </g>
)

// ————— Panoplie du chanceux —————

// Une pinte dans une main, le chaudron d'or dans l'autre. Deux empilements comptent :
// la bière est peinte DANS le verre translucide et la mousse par-dessus le bord, sinon on
// voit un bloc ambre ; et les pièces passent AVANT le bord du chaudron, sinon elles ont
// l'air posées devant plutôt que dedans.
const LuckyArms = () => (
  <g>
    <path d="M44 42 L27 53 L17 66" fill="none" stroke="#2f7d4f" strokeWidth="14"
          strokeLinecap="round" strokeLinejoin="round" />
    <path d="M56 42 L73 53 L83 66" fill="none" stroke="#2f7d4f" strokeWidth="14"
          strokeLinecap="round" strokeLinejoin="round" />
    <ellipse cx="19" cy="64" rx="8.5" ry="6" fill="#c9a227" transform="rotate(-42 19 64)" />
    <ellipse cx="81" cy="64" rx="8.5" ry="6" fill="#c9a227" transform="rotate(42 81 64)" />
    <path d="M5 71 L29 71 L25 98 L9 98 Z" fill="#dbe3ee" opacity="0.8" />
    <path d="M8 76 L26 76 L23 96 L11 96 Z" fill="#e8a020" />
    <path d="M4 72 q2 -11 13 -7 q11 -4 13 7 z" fill="#f9f5ec" />
    <path d="M12 80 L12 93" stroke="#ffffff" strokeWidth="2.5" strokeLinecap="round" opacity="0.55" />
    <g fill="#f2b100">
      <circle cx="78" cy="74" r="5" /><circle cx="88" cy="71" r="5.5" /><circle cx="96" cy="75" r="4.5" />
    </g>
    <rect x="70" y="77" width="32" height="7" rx="3.5" fill="#31363f" />
    <path d="M73 83 q0 15 13 15 q13 0 13 -15 z" fill="#22262e" />
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
// Paramétré : le nœud de velours de la panoplie de l'intello n'est qu'un jeu de couleurs
// et une bague dorée de plus.
const BowTie = ({ wing = '#f0325b', knot = '#c81e45', band }) => (
  <g>
    <path d="M46 40 L14 28 v44 L46 60 z" fill={wing} />
    <path d="M54 40 L86 28 v44 L54 60 z" fill={wing} />
    <rect x="41" y="38" width="18" height="24" rx="6" fill={knot} />
    {band && <rect x="41" y="45" width="18" height="7" fill={band} />}
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
  // ⚠️ Les chapeaux DESSINÉS sont calibrés à 1,5× leur taille d'origine : à `fit: 0.77` ils
  // ne couvraient que ~60 % de la largeur du crâne alors qu'un bonnet de bain ou des bois de
  // renne en couvrent 90 à 100 %, et ils avaient l'air posés sur la tête d'un autre.
  // Le `bite` passe de 14 à 18 avec : l'ancrage pose le bord bas de la BOÎTE sur le crâne,
  // et comme ces dessins laissent du vide sous eux, grandir les décollait de la tête.
  gold_hat: { view: '12 16 76 64', fit: 1.155, bite: 18,
              node: <TopHat body="#f6c945" top="#ffe08a" band="#8a6d1b" brim="#c9930a" /> },
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
  weight_belt: { view: '2 26 96 54', fit: 0.8, bite: 28, node: <WeightBelt /> },
  // fit 1.6 : le fruit occupe alors ~63 % de la boîte, et les avant-bras se logent dans le
  // tiers qui reste de chaque côté, quelle que soit sa largeur.
  wetsuit_arms: { view: '3 22 98 72', pair: true, back: true, fit: 1.6, minEm: 0.6, maxEm: 1.05,
                  node: <WetsuitArms /> },
  // — Panoplie du loup —
  wolf_ears: { view: '6 24 88 78', fit: 0.9, node: <WolfEars /> },
  scar: { view: '11 25 20 50', em: 0.5, node: <Scar /> },
  spiked_collar: { view: '4 8 92 58', fit: 0.8, bite: 23, node: <SpikedCollar /> },
  wolf_paws: { view: '8 42 84 44', pair: true, node: <Pair as={PawFoot} fur="#6b6f7a" pad="#3f434c" /> },
  // — Panoplie de Noël. Deux pièces ne sont qu'un RECOLORIAGE : les dessins de la moufle et
  // de la chaussure sont déjà paramétrés, une panoplie de plus ne coûte que des couleurs.
  antlers: { view: '4 28 92 74', fit: 1.0, node: <Antlers /> },
  santa_glasses: { view: '0 0 100 68', fit: 1.05, node: <SantaGlasses /> },
  // — Panoplie du Père Noël. Le bonnet réutilise `santa_hat` : c'est le même objet que le
  // Bonnet du Réveillon, le redessiner en plus gros aurait dupliqué du contenu pour rien.
  beard: { view: '16 48 68 54', fit: 1.12, minEm: 0.4, maxEm: 0.82, node: <Beard /> },
  gift_arms: { view: '0 40 100 56', pair: true, back: true, fit: 1.6, minEm: 0.6, maxEm: 1.05,
               node: <GiftArms /> },
  santa_boots: { view: '8 25 84 55', pair: true,
                 node: <Pair body="#1f2229" sole="#0f1216" tongue="#f4f7fd" lace="#f2b100" shaft={16} /> },
  garland: { view: '0 20 100 40', fit: 0.85, bite: 26, node: <Garland /> },
  xmas_arms: { view: '0 40 100 54', pair: true, back: true, fit: 1.6, minEm: 0.6, maxEm: 1.05,
               node: <XmasArms /> },
  xmas_boots: { view: '8 25 84 55', pair: true,
                node: <Pair body="#c0182f" sole="#3f434c" tongue="#f4f7fd" lace="#ffffff" shaft={14} /> },
  bowtie: { view: '10 24 80 52', em: 0.26, node: <BowTie /> },
  // — Panoplie de l'intello. Le haut-de-forme et le monocle sont les dessins EXISTANTS :
  // la panoplie les rapatrie plutôt que d'en créer des sosies.
  // `anim` : le nœud de velours fait un tour sur lui-même, 2 s toutes les 3 s. Une pièce de
  // panoplie de haut rang a le droit de bouger — c'est ce qui la distingue de loin.
  bowtie_lux: { view: '10 24 80 52', em: 0.28, anim: 'spin',
                node: <BowTie wing="#8e1122" knot="#5e0b16" band="#c9a227" /> },
  dress_shoes: { view: '8 40 84 40', pair: true,
                 node: <Pair as={DressShoe} body="#1b1b22" sole="#0b0b10" shine="#8d95a3" /> },
  scholar_arms: { view: '0 40 100 60', pair: true, back: true, fit: 1.6, minEm: 0.6, maxEm: 1.05,
                  node: <ScholarArms /> },
  // — Panoplie du chanceux. Quatre pièces, dont TROIS ne sont qu'un paramétrage de dessins
  // existants : le haut-de-forme, la barbe et la chaussure de ville étaient déjà découpés.
  leprechaun_hat: { view: '12 16 76 64', fit: 1.155, bite: 18,
                    node: <TopHat body="#2f7d4f" top="#46a06a" band="#16281d" brim="#1f5b3a" buckle="#f2b100" /> },
  red_beard: { view: '16 48 68 54', fit: 1.12, minEm: 0.4, maxEm: 0.82,
               node: <Beard hair="#c2622a" shade="#9a4a1c" /> },
  buckle_shoes: { view: '8 40 84 40', pair: true,
                  node: <Pair as={DressShoe} body="#16281d" sole="#0b120d" shine="#8d95a3" buckle="#f2b100" /> },
  lucky_arms: { view: '0 40 100 60', pair: true, back: true, fit: 1.6, minEm: 0.6, maxEm: 1.05,
                node: <LuckyArms /> },
  cowboy_hat: { view: '8 30 84 52', fit: 1.155, bite: 18, node: <CowboyHat /> },
  santa_hat: { view: '18 22 79 62', fit: 1.155, bite: 18, node: <SantaHat /> },
  bucket_hat: { view: '10 34 80 48', fit: 1.095, bite: 18, node: <BucketHat /> },
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
