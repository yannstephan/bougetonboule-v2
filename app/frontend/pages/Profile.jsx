import { Head, Link } from '@inertiajs/react'
import PlayerAvatar from '../components/PlayerAvatar'
import SubHeader from '../components/SubHeader'
import { statusChip } from '../lib/labels'

export default function Profile({ player, stats, trainings }) {
  return (
    <div className="shell">
      <Head title={player.name} />
      <SubHeader title="Profil" />

      <main className="body">
        <div className="pf-head">
          <PlayerAvatar avatar={player.avatar} size={72} />
          <div className="pf-id">
            <div className="pf-name">{player.name}{player.is_me && <span className="pf-me">toi</span>}</div>
            <div className="pf-team" style={{ color: player.team.color }}>
              {player.team.name}{player.fruit_name ? ` · ${player.fruit_name}` : ''}
            </div>
          </div>
        </div>

        <div className="pf-stats pf-stats-3">
          <Stat value={`${stats.total_km} km`} label="Total validé" />
          <Stat value={stats.trainings_count} label="Sorties" />
          <Stat value={`${stats.month_score} 🍑`} label="Ce mois-ci" />
        </div>

        <h2 className="pf-h2">Sorties</h2>
        {trainings.length === 0
          ? <p className="pf-empty">Aucune sortie importée pour l'instant.</p>
          : <ul className="run-list">
              {trainings.map((t) => <li key={t.id}><Run t={t} /></li>)}
            </ul>}
      </main>
    </div>
  )
}

function Stat({ value, label }) {
  return (
    <div className="pf-stat">
      <div className="v">{value}</div>
      <div className="l">{label}</div>
    </div>
  )
}

function Run({ t }) {
  const chip = statusChip(t.status)
  return (
    <Link href={`/courses/${t.id}`} className="run">
      <div className="run-day">
        <span className="d">{t.date}</span>
        <span className="h">{t.time}</span>
      </div>
      <div className="run-main">
        <div className="run-title">{t.title}{t.has_route && <span className="run-ic" title="Tracé dispo">🗺️</span>}{t.has_photo && <span className="run-ic" title="Photo">📷</span>}</div>
        <div className="run-sub">
          {t.km} km{t.duration ? ` · ${t.duration}` : ''} · <span className={`run-chip ${chip.cls}`}>{chip.label}</span>
        </div>
      </div>
      <div className="run-balls">+{t.balls} 🍑</div>
    </Link>
  )
}
