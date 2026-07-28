// Monstres des deux clans d'Odyssea, en SVG plat (viewBox 100×100).
//   - king-coco   : roi noix de coco (Fruits exotiques)
//   - framboitrix : sorcière-framboise, clin d'œil à Bellatrix Lestrange (Fruits rouges)
// Le `slug` vient du back (Monster#slug). Un monstre inconnu retombe sur un emoji.
export default function Monster({ slug, name, size = 96, className = '' }) {
  const Draw = MONSTERS[slug]
  return (
    <span className={`mon ${className}`} style={{ width: size, height: size }} role="img" aria-label={name || slug}>
      {Draw
        ? <svg viewBox="0 0 100 100" className="mon-svg"><Draw /></svg>
        : <span style={{ fontSize: size * 0.7 }}>👾</span>}
    </span>
  )
}

// Roi noix de coco : coque brune poilue, couronne dorée, air renfrogné.
function KingCoco() {
  return (
    <g>
      <ellipse cx="50" cy="88" rx="26" ry="5" fill="#000" opacity="0.12" />
      {/* couronne */}
      <path d="M28 26 L34 12 L42 22 L50 8 L58 22 L66 12 L72 26 Z" fill="#f6c945" stroke="#d9a520" strokeWidth="1.5" strokeLinejoin="round" />
      <circle cx="50" cy="9" r="2.4" fill="#f0325b" />
      <circle cx="34" cy="13" r="2" fill="#12b58a" />
      <circle cx="66" cy="13" r="2" fill="#12b58a" />
      <rect x="28" y="25" width="44" height="5" rx="2" fill="#e0a80c" />
      {/* coque */}
      <circle cx="50" cy="58" r="32" fill="#7a5230" />
      <circle cx="50" cy="58" r="32" fill="none" stroke="#5c3c22" strokeWidth="2" />
      {/* poils / fibres */}
      <g stroke="#5c3c22" strokeWidth="1.4" opacity="0.6" strokeLinecap="round">
        <path d="M24 50 l-6 -3 M22 60 l-7 0 M26 70 l-6 4 M74 50 l6 -3 M78 60 l7 0 M74 70 l6 4 M50 88 l0 7" />
      </g>
      {/* trois yeux de coco fâchés */}
      <circle cx="38" cy="54" r="7" fill="#3c2818" />
      <circle cx="62" cy="54" r="7" fill="#3c2818" />
      <circle cx="39" cy="53" r="3.4" fill="#fff" /><circle cx="40" cy="53.5" r="1.8" fill="#2b2333" />
      <circle cx="63" cy="53" r="3.4" fill="#fff" /><circle cx="64" cy="53.5" r="1.8" fill="#2b2333" />
      <path d="M30 46 l14 3 M70 46 l-14 3" stroke="#2b1a0e" strokeWidth="2.4" strokeLinecap="round" />
      {/* bouche grognon avec crocs */}
      <path d="M38 72 Q50 66 62 72" fill="none" stroke="#2b1a0e" strokeWidth="2.6" strokeLinecap="round" />
      <path d="M44 70 l2 5 l2 -5 Z M54 70 l2 5 l2 -5 Z" fill="#fff" />
    </g>
  )
}

// Framboitrix : sorcière-framboise (clin d'œil à Bellatrix Lestrange). Amas de drupéoles
// magenta, chapeau pointu de sorcière penché, regard maléfique et rictus édenté.
function Framboitrix() {
  const rows = [
    { y: 47, xs: [43, 50, 57] },
    { y: 54, xs: [36, 43, 50, 57, 64] },
    { y: 61, xs: [34, 42, 50, 58, 66] },
    { y: 68, xs: [37, 44, 51, 58, 63] },
    { y: 75, xs: [42, 50, 58] },
    { y: 82, xs: [46, 54] }
  ]
  const drupes = rows.flatMap((r) => r.xs.map((x) => [x, r.y]))
  // Trois mèches ondulées de chaque côté [xDépart, yDépart, dérive, longueur, ondulations, ampleur, sens].
  const locks = [
    [37, 41, -15, 47, 3, 8, 1], [35, 44, -9, 46, 3, 7, -1], [34, 47, -4, 42, 3, 6, 1],
    [63, 41, 15, 47, 3, 8, -1], [65, 44, 9, 46, 3, 7, 1], [66, 47, 4, 42, 3, 6, -1]
  ].map((a) => wavyLock(...a))
  return (
    <g>
      <ellipse cx="50" cy="91" rx="24" ry="4.5" fill="#000" opacity="0.12" />
      {/* cheveux de sorcière : trois mèches franchement ondulées de chaque côté, sous le chapeau */}
      <g fill="none" stroke="#20101f" strokeWidth="6" strokeLinecap="round">
        {locks.map((d, i) => <path key={i} d={d} />)}
      </g>
      <g fill="none" stroke="#5a3355" strokeWidth="1.6" strokeLinecap="round" opacity="0.75">
        {locks.map((d, i) => <path key={`s${i}`} d={d} />)}
      </g>
      {/* corps : amas de drupéoles */}
      {drupes.map(([x, y], i) => (
        <circle key={i} cx={x} cy={y} r="5.4" fill="#d62d63" stroke="#a01e49" strokeWidth="0.8" />
      ))}
      {drupes.map(([x, y], i) => (
        <circle key={`h${i}`} cx={x - 1.7} cy={y - 1.7} r="1.5" fill="#f79bb8" opacity="0.85" />
      ))}
      {/* yeux maléfiques (en amande, inclinés) */}
      <ellipse cx="43" cy="59" rx="5.6" ry="6.6" fill="#fff" transform="rotate(-14 43 59)" />
      <ellipse cx="57" cy="59" rx="5.6" ry="6.6" fill="#fff" transform="rotate(14 57 59)" />
      <circle cx="44" cy="60" r="2.7" fill="#2b1030" />
      <circle cx="56" cy="60" r="2.7" fill="#2b1030" />
      <circle cx="43.2" cy="59" r="0.9" fill="#fff" />
      <circle cx="55.2" cy="59" r="0.9" fill="#fff" />
      {/* sourcils froncés + rictus édenté */}
      <path d="M35 52 l12 4 M65 52 l-12 4" stroke="#3e0f28" strokeWidth="2.4" strokeLinecap="round" />
      <path d="M42 71 Q50 77 58 71" fill="none" stroke="#3e0f28" strokeWidth="2.4" strokeLinecap="round" />
      <path d="M47 72 l1.4 3.6 l1.4 -3.6 Z" fill="#fff" />
      {/* chapeau de sorcière, penché */}
      <g transform="rotate(-8 50 34)">
        <ellipse cx="50" cy="37" rx="29" ry="6" fill="#241033" />
        <path d="M41 38 L59 38 L55 8 Q54 4 51 8 Z" fill="#2e1440" stroke="#180a24" strokeWidth="1" strokeLinejoin="round" />
        <path d="M42 33 Q50 36 57 32 L56 37 Q49 39 43 37 Z" fill="#c0295a" />
        <circle cx="52.5" cy="6.5" r="2.1" fill="#c0295a" />
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

const MONSTERS = { 'king-coco': KingCoco, framboitrix: Framboitrix }
