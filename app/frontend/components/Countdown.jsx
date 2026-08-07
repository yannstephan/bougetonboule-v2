import { useEffect, useState } from 'react'

// Le jour J, en une seule ligne : une pastille « J-227 », le nom et la date de la course,
// et la progression de la prépa. La version longue (jours/heures/min/sec + coureur qui
// avance sur sa piste) prenait le tiers du Hub pour une info qu'on lit d'un coup d'œil.

// Ce qu'affiche la pastille. Au-delà d'un jour on compte en jours ; le dernier jour, en
// heures — sinon la pastille resterait figée sur « 0 J » pendant 24 h.
function badge(target, now) {
  const ms = target - now
  if (ms <= 0) return { n: '🎉', u: 'jour J', done: true }

  const days = Math.floor(ms / 86_400_000)
  if (days >= 1) return { n: days, u: days > 1 ? 'jours' : 'jour' }

  const hours = Math.max(1, Math.floor(ms / 3_600_000))
  return { n: hours, u: hours > 1 ? 'heures' : 'heure', soon: true }
}

// La prépa, comptée en semaines entre la ligne de départ (starts_at) et l'arrivée.
// Une semaine parle plus qu'un pourcentage quand on prépare une course.
function prep(startAt, target, now) {
  if (!startAt) return null

  const start = new Date(startAt).getTime()
  if (!(target > start)) return null

  const total = Math.max(1, Math.ceil((target - start) / 604_800_000))
  const done = Math.min(Math.max(0, now - start), target - start)
  return {
    week: Math.min(total, Math.floor(done / 604_800_000) + 1),
    total,
    pct: (done / (target - start)) * 100,
  }
}

export default function Countdown({ raceAt, startAt, name, location }) {
  const target = new Date(raceAt).getTime()
  const [now, setNow] = useState(() => Date.now())

  // La minute suffit : plus rien ne bat à la seconde depuis qu'on affiche des jours.
  useEffect(() => {
    const id = setInterval(() => setNow(Date.now()), 60_000)
    return () => clearInterval(id)
  }, [])

  const left = badge(target, now)
  const run = prep(startAt, target, now)
  const date = new Date(raceAt).toLocaleDateString('fr-FR', { day: 'numeric', month: 'long', year: 'numeric' })

  return (
    <div className="cd">
      <div className={`cd-badge ${left.done ? 'go' : ''}`}>
        <b>{left.n}</b>
        <span>{left.u}</span>
      </div>
      <div className="cd-main">
        <div className="cd-name">{name || 'Le jour de la course'}</div>
        <div className="cd-meta">{date}{location ? ` · ${location}` : ''}</div>
        {run && (
          <div className="cd-run">
            <div className="cd-track"><i style={{ width: `${run.pct}%` }} /></div>
            <span className="cd-week">Semaine {run.week}/{run.total}</span>
          </div>
        )}
      </div>
    </div>
  )
}
