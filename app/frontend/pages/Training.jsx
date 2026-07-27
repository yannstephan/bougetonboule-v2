import { Head, Link } from '@inertiajs/react'
import PlayerAvatar from '../components/PlayerAvatar'
import RouteMap from '../components/RouteMap'

const statusChip = {
  verified: { label: 'Validée', cls: 'ok' },
  pending: { label: 'En attente de validation', cls: 'wait' },
  rejected: { label: 'Rejetée', cls: 'no' },
  trapped: { label: 'Piégée', cls: 'no' },
  protected: { label: 'Protégée', cls: 'wait' },
}

export default function Training({ training: t, author }) {
  const chip = statusChip[t.status] || statusChip.pending

  return (
    <div className="shell">
      <Head title={t.title} />
      <div className="subhead">
        <Link href={`/joueurs/${author.id}`} className="back">←</Link>
        <div className="ti">{t.title}</div>
      </div>

      <main className="body">
        <Link href={`/joueurs/${author.id}`} className="tr-author">
          <PlayerAvatar avatar={author.avatar} size={40} />
          <div>
            <div className="tr-author-name">{author.name}</div>
            <div className="tr-author-team" style={{ color: author.team.color }}>{author.team.name}</div>
          </div>
          <span className="tr-when">{t.day_label} · {t.time}</span>
        </Link>

        {t.special_day && (
          <div className="specialday">
            🎉 Jour spécial · {t.special_day.name}
            <span className="x2">🍑 ×{t.special_day.multiplier}</span>
          </div>
        )}

        <RouteMap points={t.route_points} height={200} />

        <div className="tr-stats">
          <Stat value={`${t.km}`} unit="km" label="Distance" />
          {t.duration && <Stat value={t.duration} label="Durée" />}
          {t.pace && <Stat value={t.pace} label="Allure" />}
          {t.elevation != null && <Stat value={`${Math.round(t.elevation)}`} unit="m D+" label="Dénivelé" />}
        </div>

        <div className="tr-reward">
          <span className="tr-balls">+{t.balls} 🍑</span>
          <span className={`run-chip ${chip.cls}`}>{chip.label}</span>
        </div>

        {t.description && <p className="tr-desc">{t.description}</p>}

        {t.photo_url && (
          <img className="tr-photo" src={t.photo_url} alt={`Photo de la sortie ${t.title}`} loading="lazy" />
        )}
      </main>
    </div>
  )
}

function Stat({ value, unit, label }) {
  return (
    <div className="tr-stat">
      <div className="v">{value}{unit && <span className="u"> {unit}</span>}</div>
      <div className="l">{label}</div>
    </div>
  )
}
