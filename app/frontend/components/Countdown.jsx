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

export default function Countdown({ raceAt, name, location }) {
  const target = new Date(raceAt).getTime()
  const [t, setT] = useState(() => remaining(target))

  useEffect(() => {
    const id = setInterval(() => setT(remaining(target)), 1000)
    return () => clearInterval(id)
  }, [target])

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
