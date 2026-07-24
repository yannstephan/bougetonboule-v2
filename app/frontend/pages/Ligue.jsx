import { Head, Link } from '@inertiajs/react'
import BottomNav from '../components/BottomNav'

const ordinal = (n) => (n === 1 ? '1er' : `${n}e`)

const zoneLabel = {
  promotion: '▲ Zone de promotion',
  relegation: '▼ Zone de relégation',
}

const lastWeekLabel = {
  promoted: (r) => `⬆️ Promu·e la semaine dernière (${ordinal(r)})`,
  relegated: (r) => `⬇️ Relégué·e la semaine dernière (${ordinal(r)})`,
  stayed: (r) => `➡️ ${ordinal(r)} la semaine dernière`,
}

export default function Ligue({ division, divisions, week, counts, rows, me, last_week, balls }) {
  return (
    <div className="shell">
      <Head title="Ligue" />
      <div className="subhead">
        <Link href="/" className="back">←</Link>
        <div className="ti">🏅 Ligue</div>
        <span className="curr" style={{ marginLeft: 'auto' }}>🍑 {balls}</span>
      </div>

      <main className="body">
        <DivisionStrip divisions={divisions} current={division.key} />
        <DivisionCard division={division} me={me} total={rows.length} week={week} />
        {last_week && <div className="lg-last">{lastWeekLabel[last_week.result](last_week.rank)}</div>}

        {rows.length === 0
          ? <p className="lg-empty">Personne dans cette division pour l'instant.</p>
          : <Standings rows={rows} counts={counts} />}

        <p className="lg-rules">
          1 km couru = 1 🍑 (max 10 par sortie). Le classement repart de zéro chaque lundi :
          les {counts.promoted || 0} premiers montent d'une division, les {counts.relegated || 0} derniers
          descendent. Une semaine sans courir fait descendre.
        </p>
      </main>

      <BottomNav active="ligue" />
    </div>
  )
}

function DivisionStrip({ divisions, current }) {
  return (
    <div className="lg-strip">
      {divisions.map((d) => (
        <div key={d.key} className={`lg-tier ${d.key === current ? 'on' : ''}`} title={d.name}>
          <span className="e">{d.emoji}</span>
          <span className="n">{d.name}</span>
        </div>
      ))}
    </div>
  )
}

function DivisionCard({ division, me, total, week }) {
  return (
    <div className="lg-card">
      <div className="lg-emoji">{division.emoji}</div>
      <div className="lg-meta">
        <div className="lg-title">Division {division.name}</div>
        <div className="lg-sub">
          {me ? `${ordinal(me.rank)} sur ${total} · ${me.score} 🍑 cette semaine` : `${total} joueurs`}
        </div>
      </div>
      <div className="lg-clock">
        <div className="d">{week.days_left}</div>
        <div className="l">{week.days_left > 1 ? 'jours' : 'jour'}</div>
      </div>
    </div>
  )
}

function Standings({ rows, counts }) {
  const firstSafe = counts.promoted > 0 ? counts.promoted : -1
  const firstReleg = counts.relegated > 0 ? rows.length - counts.relegated : -1

  return (
    <ol className="lg-list">
      {rows.map((row, i) => (
        <li key={row.id}>
          {i === firstSafe && <Divider kind="promotion" />}
          {i === firstReleg && <Divider kind="relegation" />}
          <Standing row={row} />
        </li>
      ))}
    </ol>
  )
}

function Divider({ kind }) {
  return <div className={`lg-div ${kind}`}>{zoneLabel[kind]}</div>
}

function Standing({ row }) {
  return (
    <div className={`lg-row ${row.zone} ${row.me ? 'me' : ''}`}>
      <span className="lg-rank">{row.rank}</span>
      <span className="lg-ava" style={{ background: row.team.color }}>{row.initial}</span>
      <span className="lg-name">
        {row.name}{row.me && <b> · toi</b>}
        <span className="lg-team">{row.team.name}</span>
      </span>
      <span className="lg-score">
        {row.score} 🍑
        <span className="lg-km">{row.km} km · {row.trainings} sortie{row.trainings > 1 ? 's' : ''}</span>
      </span>
    </div>
  )
}
