// Monstres des deux clans d'Odyssea, en SVG plat (viewBox 100×100).
//   - king-coco   : roi noix de coco (Fruits exotiques)
//   - framboitrix : sorcière-framboise, clin d'œil à Bellatrix Lestrange (Fruits rouges)
// Le `slug` vient du back (Monster#slug). Un monstre inconnu retombe sur un emoji.
//
// Trois modificateurs d'apparence, tous pilotés par la donnée du MonsterPresenter :
//   - `wear` (0→3) : paliers de PV franchis (75 / 50 / 25 %). Le monstre est de moins en moins
//     en forme — couronne de travers, coque fendue, drupéoles perdues, yeux K.-O. Cliquet côté
//     back (Monster#refresh_state!) : un soin ne répare jamais les dégâts déjà encaissés.
//   - `creamed` : chantilly plein les yeux tant que l'effet dure (ses PV s'affichent « ??? »).
//   - `shielded` : saladier transparent retourné par-dessus (le monstre est intouchable).
export default function Monster({ slug, name, size = 96, className = '',
                                  wear = 0, creamed = false, shielded = false }) {
  const Draw = MONSTERS[slug]
  const w = Math.min(3, Math.max(0, Math.round(wear) || 0))
  const eyes = EYES[slug]
  return (
    <span className={`mon${w ? ` wear${w}` : ''} ${className}`} style={{ width: size, height: size }}
          role="img" aria-label={describe(name || slug, w, creamed, shielded)}>
      {Draw
        ? (
          <svg viewBox="0 0 100 100" className="mon-svg">
            {/* Le bord arrière du saladier passe DERRIÈRE le monstre (il est dedans), le reste
                de la cloche par-dessus. Sous le saladier, il rentre la tête dans les épaules. */}
            {shielded && <BowlBack />}
            <g transform={shielded ? 'translate(50 90) scale(.74) translate(-50 -90)' : undefined}>
              <Draw wear={w} />
              {creamed && eyes && <Cream eyes={eyes} />}
            </g>
            {shielded && <SaladBowl />}
          </svg>
        )
        : <span style={{ fontSize: size * 0.7 }}>👾</span>}
    </span>
  )
}

// Ancres des yeux, par monstre : c'est là que la chantilly s'écrase.
const EYES = {
  'king-coco': { left: [38, 54], right: [62, 54], r: 9 },
  framboitrix: { left: [43, 59], right: [57, 59], r: 8 }
}

const WEAR_WORDS = ['', 'un peu amoché', 'mal en point', 'au bout du rouleau']

function describe(name, wear, creamed, shielded) {
  return [name, WEAR_WORDS[wear], creamed && 'chantilly plein les yeux', shielded && 'sous un saladier']
    .filter(Boolean).join(', ')
}

// Roi noix de coco : coque brune poilue, couronne dorée, air renfrogné.
// L'usure fend la coque, fait glisser la couronne et éteint le regard.
function KingCoco({ wear }) {
  const shell = ['#7a5230', '#71492b', '#674126', '#5b3821'][wear]
  const cracks = ['M32 40 l5 7 l-4 4 l6 7', 'M70 45 l-6 6 l5 5 l-6 6', 'M46 80 l4 -7 l-5 -5 l4 -6']
  return (
    <g>
      <ellipse cx="50" cy="88" rx="26" ry="5" fill="#000" opacity="0.12" />
      {/* couronne : elle glisse un peu plus à chaque palier et perd ses pierres */}
      <g transform={`rotate(${wear * -5} 50 27)`}>
        <path d="M28 26 L34 12 L42 22 L50 8 L58 22 L66 12 L72 26 Z" fill="#f6c945" stroke="#d9a520" strokeWidth="1.5" strokeLinejoin="round" />
        <circle cx="50" cy="9" r="2.4" fill="#f0325b" />
        {wear < 3 && <circle cx="34" cy="13" r="2" fill="#12b58a" />}
        {wear < 2 && <circle cx="66" cy="13" r="2" fill="#12b58a" />}
        <rect x="28" y="25" width="44" height="5" rx="2" fill="#e0a80c" />
      </g>
      {/* coque, de plus en plus terne */}
      <circle cx="50" cy="58" r="32" fill={shell} />
      <circle cx="50" cy="58" r="32" fill="none" stroke="#5c3c22" strokeWidth="2" />
      {/* poils / fibres */}
      <g stroke="#5c3c22" strokeWidth="1.4" opacity="0.6" strokeLinecap="round">
        <path d="M24 50 l-6 -3 M22 60 l-7 0 M26 70 l-6 4 M74 50 l6 -3 M78 60 l7 0 M74 70 l6 4 M50 88 l0 7" />
      </g>
      {/* fêlures : une de plus par palier franchi, la chair blanche du coco apparaît dessous */}
      <g fill="none" strokeLinecap="round" strokeLinejoin="round">
        {cracks.slice(0, wear).map((d, i) => <path key={`c${i}`} d={d} stroke="#33200f" strokeWidth="3.4" />)}
        {cracks.slice(0, wear).map((d, i) => <path key={i} d={d} stroke="#f2e6d2" strokeWidth="1.6" />)}
      </g>
      {/* yeux : normaux, puis paupières tombantes, puis K.-O. */}
      {wear < 3 ? (
        <>
          <circle cx="38" cy="54" r="7" fill="#3c2818" />
          <circle cx="62" cy="54" r="7" fill="#3c2818" />
          <circle cx="39" cy={53 + wear} r="3.4" fill="#fff" />
          <circle cx={40 - wear} cy={53.5 + wear} r="1.8" fill="#2b2333" />
          <circle cx="63" cy={53 + wear} r="3.4" fill="#fff" />
          <circle cx={64 + wear} cy={53.5 + wear} r="1.8" fill="#2b2333" />
          {wear === 2 && (
            <g fill={shell}>
              <path d="M31 54 a7 7 0 0 1 14 0 z" />
              <path d="M55 54 a7 7 0 0 1 14 0 z" />
            </g>
          )}
        </>
      ) : (
        <g stroke="#2b1a0e" strokeWidth="2.8" strokeLinecap="round">
          <path d="M33 49 l9 9 M42 49 l-9 9 M58 49 l9 9 M67 49 l-9 9" />
        </g>
      )}
      <path d="M30 46 l14 3 M70 46 l-14 3" stroke="#2b1a0e" strokeWidth="2.4" strokeLinecap="round" />
      {/* bouche : grognon, puis crispée (un seul croc), puis pendante avec la langue dehors */}
      {wear < 2 && (
        <>
          <path d="M38 72 Q50 66 62 72" fill="none" stroke="#2b1a0e" strokeWidth="2.6" strokeLinecap="round" />
          <path d="M44 70 l2 5 l2 -5 Z M54 70 l2 5 l2 -5 Z" fill="#fff" />
        </>
      )}
      {wear === 2 && (
        <>
          <path d="M38 73 q4 -5 8 0 t8 0 t8 0" fill="none" stroke="#2b1a0e" strokeWidth="2.6" strokeLinecap="round" />
          <path d="M44 71 l2 5 l2 -5 Z" fill="#fff" />
        </>
      )}
      {wear === 3 && (
        <>
          <ellipse cx="50" cy="74" rx="8" ry="5.5" fill="#2b1a0e" />
          <path d="M46 77 q4 7 8 0 z" fill="#e0567a" />
        </>
      )}
      {wear >= 1 && <Sweat x={76} y={38} />}
      {wear >= 2 && <Plaster x={66} y={68} angle={-28} />}
    </g>
  )
}

// Framboitrix : sorcière-framboise (clin d'œil à Bellatrix Lestrange). Amas de drupéoles
// magenta, chapeau pointu de sorcière penché, regard maléfique et rictus édenté.
// L'usure lui fait perdre des drupéoles (elles roulent à ses pieds), aplatit sa chevelure,
// déchire son chapeau et lui met la tête qui tourne.
function Framboitrix({ wear }) {
  const rows = [
    { y: 47, xs: [43, 50, 57] },
    { y: 54, xs: [36, 43, 50, 57, 64] },
    { y: 61, xs: [34, 42, 50, 58, 66] },
    { y: 68, xs: [37, 44, 51, 58, 63] },
    { y: 75, xs: [42, 50, 58] },
    { y: 82, xs: [46, 54] }
  ]
  const drupes = rows.flatMap((r) => r.xs.map((x) => [x, r.y]))
  // Drupéoles qui se détachent (2 par palier) et finissent au sol, dans cet ordre.
  const lost = new Set([22, 5, 18, 10, 1, 16].slice(0, wear * 2))
  const fallen = [[28, 88], [72, 89], [22, 85]].slice(0, wear)
  const berry = ['#d62d63', '#c92a5b', '#b82753', '#a52449'][wear]
  // Trois mèches ondulées de chaque côté [xDépart, yDépart, dérive, longueur, ondulations, ampleur, sens].
  // Départ haut et large + 4 vagues d'ampleur forte → chevelure qui enveloppe la tête ;
  // l'ampleur retombe avec l'usure : la crinière finit raide et fatiguée.
  const amp = 1 - wear * 0.22
  const locks = [
    [39, 37, -20, 52, 4, 11, 1], [35, 41, -13, 50, 4, 10, -1], [33, 46, -6, 45, 4, 8, 1],
    [61, 37, 20, 52, 4, 11, -1], [65, 41, 13, 50, 4, 10, 1], [67, 46, 6, 45, 4, 8, -1]
  ].map(([x, y, drift, len, waves, a, dir]) => wavyLock(x, y, drift, len + wear, waves, a * amp, dir))
  return (
    <g>
      <ellipse cx="50" cy="91" rx="24" ry="4.5" fill="#000" opacity="0.12" />
      {/* drupéoles tombées, au sol */}
      {fallen.map(([x, y], i) => (
        <circle key={`f${i}`} cx={x} cy={y} r="3.4" fill={berry} stroke="#a01e49" strokeWidth="0.8" opacity="0.9" />
      ))}
      {/* cheveux de sorcière : trois mèches ondulées de chaque côté, sous le chapeau */}
      <g fill="none" stroke="#20101f" strokeWidth="6" strokeLinecap="round">
        {locks.map((d, i) => <path key={i} d={d} />)}
      </g>
      <g fill="none" stroke="#5a3355" strokeWidth="1.6" strokeLinecap="round" opacity="0.75">
        {locks.map((d, i) => <path key={`s${i}`} d={d} />)}
      </g>
      {/* corps : amas de drupéoles, troué par les coups reçus */}
      {drupes.map(([x, y], i) => (lost.has(i) ? null : (
        <circle key={i} cx={x} cy={y} r="5.4" fill={berry} stroke="#a01e49" strokeWidth="0.8" />
      )))}
      {drupes.map(([x, y], i) => (lost.has(i) ? null : (
        <circle key={`h${i}`} cx={x - 1.7} cy={y - 1.7} r="1.5" fill="#f79bb8" opacity="0.85" />
      )))}
      {/* yeux maléfiques (en amande, inclinés) — la tête tourne au dernier palier */}
      <ellipse cx="43" cy="59" rx="5.6" ry="6.6" fill="#fff" transform="rotate(-14 43 59)" />
      <ellipse cx="57" cy="59" rx="5.6" ry="6.6" fill="#fff" transform="rotate(14 57 59)" />
      {wear < 3 ? (
        <>
          <circle cx={44 - wear} cy={60 + wear * 0.8} r="2.7" fill="#2b1030" />
          <circle cx={56 + wear} cy={60 + wear * 0.8} r="2.7" fill="#2b1030" />
          <circle cx="43.2" cy="59" r="0.9" fill="#fff" />
          <circle cx="55.2" cy="59" r="0.9" fill="#fff" />
          {wear === 2 && (
            <g fill="none" stroke="#8d5a86" strokeWidth="1.2" strokeLinecap="round" opacity="0.9">
              <path d="M39 64 q4 2.4 8 0 M53 64 q4 2.4 8 0" />
            </g>
          )}
        </>
      ) : (
        <>
          <Spiral cx={43} cy={59} r={4.6} />
          <Spiral cx={57} cy={59} r={4.6} />
        </>
      )}
      {/* sourcils froncés */}
      <path d="M35 52 l12 4 M65 52 l-12 4" stroke="#3e0f28" strokeWidth="2.4" strokeLinecap="round" />
      {/* rictus édenté, puis crispé, puis pendant */}
      {wear < 2 && (
        <>
          <path d="M42 71 Q50 77 58 71" fill="none" stroke="#3e0f28" strokeWidth="2.4" strokeLinecap="round" />
          <path d="M47 72 l1.4 3.6 l1.4 -3.6 Z" fill="#fff" />
        </>
      )}
      {wear === 2 && (
        <path d="M41 73 q3 -4 6 0 t6 0 t6 0" fill="none" stroke="#3e0f28" strokeWidth="2.4" strokeLinecap="round" />
      )}
      {wear === 3 && (
        <>
          <ellipse cx="50" cy="74" rx="6.4" ry="4.6" fill="#3e0f28" />
          <path d="M47 76 q3 6 6 0 z" fill="#f07a9c" />
        </>
      )}
      {wear >= 1 && <Sweat x={70} y={47} />}
      {wear >= 2 && <Plaster x={38} y={78} angle={22} w={13} />}
      {/* chapeau de sorcière, de plus en plus penché — et déchiré à la fin */}
      <g transform={`rotate(${-8 - wear * 5} 50 34)`}>
        <ellipse cx="50" cy="37" rx="29" ry="6" fill="#241033" />
        {/* le cône se déchire (encoche sur le bord gauche) à partir du 2e palier */}
        <path d={wear >= 2 ? 'M41 38 L59 38 L55 8 Q54 4 51 8 L53 20 L48 16 L52 26 Z' : 'M41 38 L59 38 L55 8 Q54 4 51 8 Z'}
              fill="#2e1440" stroke="#180a24" strokeWidth="1" strokeLinejoin="round" />
        <path d="M42 33 Q50 36 57 32 L56 37 Q49 39 43 37 Z" fill="#c0295a" />
        {wear < 3 && <circle cx="52.5" cy="6.5" r="2.1" fill="#c0295a" />}
      </g>
    </g>
  )
}

// Une mèche de cheveux ondulée : descend de (x,y) sur `len`, dérive de `drift` en x, avec
// `waves` ondulations d'ampleur `amp` (le signe `dir` donne le sens de la première vague).
// Chaîne de courbes quadratiques dont le point de contrôle balance de part et d'autre.
function wavyLock(x, y, drift, len, waves, amp, dir) {
  const seg = len / waves
  let d = `M${x} ${y}`
  for (let i = 0; i < waves; i++) {
    const cy = (y + seg * (i + 0.5)).toFixed(1)
    const ny = (y + seg * (i + 1)).toFixed(1)
    const nx = x + (drift * (i + 1)) / waves
    const cx = (nx + dir * amp * (i % 2 === 0 ? 1 : -1)).toFixed(1)
    d += ` Q${cx} ${cy} ${nx.toFixed(1)} ${ny}`
  }
  return d
}

// Goutte de sueur (dès le premier palier d'usure) : ça commence à chauffer.
function Sweat({ x, y }) {
  return <path d={`M${x} ${y} q2.6 3.2 0 5.2 q-2.6 -2 0 -5.2 z`} fill="#7ec8f2" stroke="#4aa8dc" strokeWidth="0.6" />
}

// Pansement de fortune, collé en travers à partir du deuxième palier.
function Plaster({ x, y, angle = -20, w = 16, h = 6 }) {
  return (
    <g transform={`rotate(${angle} ${x} ${y})`}>
      <rect x={x - w / 2} y={y - h / 2} width={w} height={h} rx={h / 2} fill="#f6d9b0" stroke="#d9b384" strokeWidth="0.8" />
      <rect x={x - w / 6} y={y - h / 2} width={w / 3} height={h} fill="#ecc596" />
      <g fill="#d9b384">
        <circle cx={x - 1.5} cy={y - 1.2} r="0.5" /><circle cx={x + 1.5} cy={y - 1.2} r="0.5" />
        <circle cx={x - 1.5} cy={y + 1.2} r="0.5" /><circle cx={x + 1.5} cy={y + 1.2} r="0.5" />
      </g>
    </g>
  )
}

// Œil en vrille : la tête qui tourne, au dernier palier.
function Spiral({ cx, cy, r, color = '#2b1030' }) {
  const d = `M${cx} ${cy} a${r * 0.3} ${r * 0.3} 0 1 1 ${r * 0.3} ${r * 0.3}` +
            ` a${r * 0.6} ${r * 0.6} 0 1 0 ${-r * 0.72} ${-r * 0.3}` +
            ` a${r} ${r} 0 1 1 ${r * 1.1} ${-r * 0.55}`
  return <path d={d} fill="none" stroke={color} strokeWidth="1.6" strokeLinecap="round" />
}

// 🍦 Chantilly : deux belles noix de crème écrasées sur les yeux, avec la coulure qui dégouline.
// Tant que l'effet dure, le monstre n'y voit plus rien — et l'équipe visée non plus (PV « ??? »).
function Cream({ eyes }) {
  return (
    <g className="mon-cream">
      <CreamSwirl cx={eyes.left[0]} cy={eyes.left[1]} r={eyes.r} />
      <CreamSwirl cx={eyes.right[0]} cy={eyes.right[1]} r={eyes.r} />
    </g>
  )
}

function CreamSwirl({ cx, cy, r }) {
  const blobs = [
    [cx, cy + r * 0.22, r * 0.86],
    [cx - r * 0.52, cy + r * 0.02, r * 0.62],
    [cx + r * 0.52, cy + r * 0.05, r * 0.6],
    [cx - r * 0.16, cy - r * 0.52, r * 0.55],
    [cx + r * 0.3, cy - r * 0.6, r * 0.44],
    [cx + r * 0.04, cy - r * 1.02, r * 0.3]
  ]
  return (
    <g>
      {/* coulure sous l'œil */}
      <path d={`M${cx - r * 0.36} ${cy + r * 0.5} q${r * 0.08} ${r * 1.1} ${r * 0.36} ${r * 1.32}`
              + ` q${r * 0.28} -${r * 0.32} ${r * 0.3} -${r * 1.28} z`} fill="#fff" />
      <circle cx={cx + r * 0.42} cy={cy + r * 2.15} r={r * 0.2} fill="#fff" />
      {blobs.map(([x, y, rr], i) => <circle key={i} cx={x} cy={y} r={rr} fill="#fff" />)}
      {/* plis de la crème */}
      <g fill="none" stroke="#e6e0ea" strokeWidth={r * 0.15} strokeLinecap="round">
        <path d={`M${cx - r * 0.5} ${cy + r * 0.36} q${r * 0.5} ${r * 0.3} ${r} 0`} />
        <path d={`M${cx - r * 0.36} ${cy - r * 0.16} q${r * 0.42} ${r * 0.26} ${r * 0.78} -${r * 0.06}`} />
      </g>
    </g>
  )
}

// Bord arrière du saladier (la moitié haute de l'ouverture) : le monstre est DEDANS, donc ce
// bord-là passe derrière lui. Dessiné avant le monstre, la cloche vient par-dessus.
function BowlBack() {
  return (
    <g className="mon-bowl">
      <path d="M2 90 A48 6.5 0 0 1 98 90 Z" fill="#bfe6ff" opacity="0.45" />
      <path d="M2 90 A48 6.5 0 0 1 98 90" fill="none" stroke="#79c9ef" strokeWidth="2.6" opacity="0.9" />
    </g>
  )
}

// 🥣 Saladier retourné : cloche translucide posée sur le monstre, plus rien ne l'atteint.
// Seul le bord AVANT est ici — l'arrière est passé derrière le monstre (BowlBack).
function SaladBowl() {
  return (
    <g className="mon-bowl">
      <path d="M2 90 A48 72 0 0 1 98 90 Z" fill="#bfe6ff" opacity="0.3" />
      <path d="M2 90 A48 6.5 0 0 0 98 90 Z" fill="#bfe6ff" opacity="0.45" />
      <path d="M2 90 A48 72 0 0 1 98 90" fill="none" stroke="#79c9ef" strokeWidth="2.6" opacity="0.9" />
      <path d="M2 90 A48 6.5 0 0 0 98 90" fill="none" stroke="#79c9ef" strokeWidth="2.6" opacity="0.9" />
      {/* le pied du saladier, en l'air puisqu'il est retourné */}
      <ellipse cx="50" cy="19.5" rx="11" ry="3.2" fill="none" stroke="#79c9ef" strokeWidth="2.2" opacity="0.9" />
      {/* reflets sur le verre */}
      <g fill="none" stroke="#fff" strokeLinecap="round" opacity="0.6">
        <path d="M17 76 A42 60 0 0 1 30 32" strokeWidth="3.2" />
        <path d="M74 31 A42 60 0 0 1 84 56" strokeWidth="2" opacity="0.7" />
      </g>
    </g>
  )
}

const MONSTERS = { 'king-coco': KingCoco, framboitrix: Framboitrix }
