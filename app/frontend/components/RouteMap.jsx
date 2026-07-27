// Tracé du parcours en SVG, sans fond de carte : on projette les points GPS [lat, lng]
// dans un cadre normalisé et on dessine la ligne + départ/arrivée. Gratuit, aucun service tiers.
export default function RouteMap({ points = [], height = 200 }) {
  if (!points || points.length < 2) {
    return <div className="route-empty" style={{ height }}>Pas de tracé pour cette sortie</div>
  }

  const W = 320
  const H = height
  const pad = 16

  // Projection : la longitude s'étire par cos(latitude) pour ne pas déformer le tracé.
  const latMid = points.reduce((s, p) => s + p[0], 0) / points.length
  const k = Math.cos((latMid * Math.PI) / 180)
  const xs = points.map((p) => p[1] * k)
  const ys = points.map((p) => -p[0]) // latitude vers le haut
  const minX = Math.min(...xs), maxX = Math.max(...xs)
  const minY = Math.min(...ys), maxY = Math.max(...ys)
  const span = Math.max(maxX - minX, maxY - minY) || 1e-6
  const ox = (W - pad * 2 - ((maxX - minX) / span) * (W - pad * 2)) / 2
  const oy = (H - pad * 2 - ((maxY - minY) / span) * (H - pad * 2)) / 2

  const proj = (x, y) => [
    pad + ox + ((x - minX) / span) * (W - pad * 2),
    pad + oy + ((y - minY) / span) * (H - pad * 2),
  ]
  const scr = xs.map((x, i) => proj(x, ys[i]))
  const d = scr.map(([x, y], i) => `${i ? 'L' : 'M'}${x.toFixed(1)} ${y.toFixed(1)}`).join(' ')
  const [sx, sy] = scr[0]
  const [ex, ey] = scr[scr.length - 1]

  return (
    <svg className="route-map" viewBox={`0 0 ${W} ${H}`} role="img" aria-label="Tracé du parcours">
      <defs>
        <pattern id="rgrid" width="26" height="26" patternUnits="userSpaceOnUse">
          <path d="M26 0H0V26" fill="none" stroke="var(--line)" strokeWidth="1" />
        </pattern>
      </defs>
      <rect x="0" y="0" width={W} height={H} fill="url(#rgrid)" rx="12" />
      <path d={d} fill="none" stroke="var(--peach)" strokeWidth="3.5" strokeLinecap="round" strokeLinejoin="round" />
      <circle cx={sx} cy={sy} r="5" fill="var(--mint)" stroke="var(--surface)" strokeWidth="2" />
      <circle cx={ex} cy={ey} r="5" fill="var(--fraise)" stroke="var(--surface)" strokeWidth="2" />
    </svg>
  )
}
