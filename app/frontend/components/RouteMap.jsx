import { useEffect, useRef } from 'react'
import L from 'leaflet'
import 'leaflet/dist/leaflet.css'

// Tracé du parcours sur un vrai fond de carte (Leaflet + tuiles OpenStreetMap, comme la v1).
// Les tuiles OSM sont gratuites ; seule l'attribution est obligatoire.
export default function RouteMap({ points = [], height = 200 }) {
  const el = useRef(null)

  useEffect(() => {
    if (!el.current || !points || points.length < 2) return

    const map = L.map(el.current, { scrollWheelZoom: false })
    L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
      maxZoom: 18,
      attribution: '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a>',
    }).addTo(map)

    const css = getComputedStyle(document.documentElement)
    const color = (name, fallback) => css.getPropertyValue(name).trim() || fallback

    const line = L.polyline(points, {
      color: color('--peach', '#ff9d76'), weight: 4, lineCap: 'round', lineJoin: 'round',
    }).addTo(map)
    const dot = (latlng, fillColor) =>
      L.circleMarker(latlng, { radius: 6, color: '#fff', weight: 2, fillColor, fillOpacity: 1 }).addTo(map)
    dot(points[0], color('--mint', '#2fbf8f'))
    dot(points[points.length - 1], color('--fraise', '#e5484d'))

    map.fitBounds(line.getBounds(), { padding: [24, 24] })

    return () => map.remove()
  }, [points])

  if (!points || points.length < 2) {
    return <div className="route-empty" style={{ height }}>Pas de tracé pour cette sortie</div>
  }

  return <div ref={el} className="route-map" style={{ height }} aria-label="Carte du parcours" />
}
