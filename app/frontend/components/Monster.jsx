// Monstres des deux clans d'Odyssea, en SVG plat (viewBox 100×100).
//   - king-coco : roi noix de coco (Fruits exotiques)
//   - dracassis : dragon cassis (Fruits rouges)
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

// Dracassis : petit dragon aux écailles cassis, ailes membranées, museau fumant.
function Dracassis() {
  return (
    <g>
      <ellipse cx="50" cy="88" rx="26" ry="5" fill="#000" opacity="0.12" />
      {/* ailes */}
      <path d="M24 52 C6 40 4 60 16 66 C10 70 18 76 28 68 Z" fill="#7b3f8c" stroke="#5b2c6f" strokeWidth="1.5" />
      <path d="M76 52 C94 40 96 60 84 66 C90 70 82 76 72 68 Z" fill="#7b3f8c" stroke="#5b2c6f" strokeWidth="1.5" />
      {/* corps */}
      <circle cx="50" cy="56" r="30" fill="#5b2c6f" />
      {/* ventre */}
      <ellipse cx="50" cy="64" rx="16" ry="18" fill="#8e5aa0" />
      {/* écailles crâne */}
      <g fill="#3e1c4a">
        <path d="M50 26 l-5 -12 l10 0 z" />
        <path d="M38 30 l-4 -10 l8 1 z" />
        <path d="M62 30 l4 -10 l-8 1 z" />
      </g>
      {/* cornes */}
      <path d="M36 34 l-8 -10" stroke="#d6cfe4" strokeWidth="4" strokeLinecap="round" />
      <path d="M64 34 l8 -10" stroke="#d6cfe4" strokeWidth="4" strokeLinecap="round" />
      {/* yeux jaunes menaçants */}
      <ellipse cx="40" cy="52" rx="7" ry="8" fill="#ffd93b" />
      <ellipse cx="60" cy="52" rx="7" ry="8" fill="#ffd93b" />
      <ellipse cx="40" cy="53" rx="2.4" ry="4.5" fill="#2b2333" />
      <ellipse cx="60" cy="53" rx="2.4" ry="4.5" fill="#2b2333" />
      <path d="M31 45 l12 4 M69 45 l-12 4" stroke="#2b1030" strokeWidth="2.4" strokeLinecap="round" />
      {/* museau + crocs + fumée */}
      <ellipse cx="50" cy="68" rx="12" ry="9" fill="#6b3a7e" />
      <circle cx="45" cy="66" r="1.4" fill="#2b1030" />
      <circle cx="55" cy="66" r="1.4" fill="#2b1030" />
      <path d="M44 74 l2 5 l2 -5 Z M54 74 l2 5 l2 -5 Z" fill="#fff" />
      <g fill="#c9b3d6" opacity="0.7">
        <circle cx="40" cy="80" r="2.2" /><circle cx="36" cy="84" r="1.6" /><circle cx="60" cy="80" r="2.2" />
      </g>
    </g>
  )
}

const MONSTERS = { 'king-coco': KingCoco, dracassis: Dracassis }
