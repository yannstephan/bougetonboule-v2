import { useEffect, useState } from 'react'

// Décompte jusqu'au jour J de la course. `raceAt` = timestamp ISO fourni par le serveur.
function remaining(target) {
  const ms = Math.max(0, target - Date.now())
  const s = Math.floor(ms / 1000)
  return {
    done: ms === 0,
    d: Math.floor(s / 86400),
    h: Math.floor((s % 86400) / 3600),
    m: Math.floor((s % 3600) / 60),
    s: s % 60,
  }
}

const pad = (n) => String(n).padStart(2, '0')

// Progression 0→100 entre la ligne de départ (starts_at) et l'arrivée (raceAt).
function progress(startAt, target) {
  if (!startAt) return null
  const start = new Date(startAt).getTime()
  if (!(target > start)) return null
  return Math.min(100, Math.max(0, ((Date.now() - start) / (target - start)) * 100))
}

export default function Countdown({ raceAt, startAt, name, location }) {
  const target = new Date(raceAt).getTime()
  const [t, setT] = useState(() => remaining(target))
  const [pct, setPct] = useState(() => progress(startAt, target))

  useEffect(() => {
    const tick = () => { setT(remaining(target)); setPct(progress(startAt, target)) }
    const id = setInterval(tick, 1000)
    return () => clearInterval(id)
  }, [target, startAt])

  const date = new Date(raceAt).toLocaleDateString('fr-FR', { day: 'numeric', month: 'long', year: 'numeric' })

  return (
    <div className="countdown">
      <div className="cd-head">
        <span className="cd-flag">🏁</span>
        <div>
          <div className="cd-title">{name || 'Le jour de la course'}</div>
          <div className="cd-date">{date}{location ? ` · ${location}` : ''}</div>
        </div>
      </div>
      {t.done ? (
        <div className="cd-go">C'est le grand jour ! 🎉</div>
      ) : (
        <div className="cd-grid">
          <Unit n={t.d} l="jours" />
          <Unit n={pad(t.h)} l="heures" />
          <Unit n={pad(t.m)} l="min" />
          <Unit n={pad(t.s)} l="sec" />
        </div>
      )}

      {pct !== null && (
        <div className="cd-progress">
          <div className="cd-lane">
            <span className="cd-runner" style={{ left: `${pct}%` }}>🏃</span>
            <span className="cd-finish">🏁</span>
          </div>
          <div className="cd-bar"><i style={{ width: `${pct}%` }} /></div>
          <div className="cd-pct">{Math.round(pct)} % du parcours</div>
        </div>
      )}
    </div>
  )
}

function Unit({ n, l }) {
  return (
    <div className="cd-unit">
      <div className="cd-n">{n}</div>
      <div className="cd-l">{l}</div>
    </div>
  )
}
