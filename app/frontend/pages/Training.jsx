import { Head, Link } from '@inertiajs/react'
import PlayerAvatar from '../components/PlayerAvatar'
import RouteMap from '../components/RouteMap'
import Hud from '../components/Hud'
import BottomNav from '../components/BottomNav'

const statusChip = {
  verified: { label: 'Validée', cls: 'ok' },
  pending: { label: 'En attente', cls: 'wait' },
  rejected: { label: 'Non comptée', cls: 'no' },
  trapped: { label: 'Piégée', cls: 'no' },
  protected: { label: 'Protégée', cls: 'wait' },
}

export default function Training({ training: t, author }) {
  const chip = statusChip[t.status] || statusChip.pending

  return (
    <div className="shell">
      <Head title={t.title} />
      <Hud />

      <main className="body">
        {/* Le titre venait du bandeau de page, supprimé partout : il descend ici, car c'est
            le nom Strava de la sortie — une info du contenu, pas un libellé de navigation. */}
        <h1 className="tr-title">{t.title}</h1>

        <Link href={`/joueurs/${author.id}`} className="tr-author">
          <PlayerAvatar avatar={author.avatar} size={40} />
          <div>
            <div className="tr-author-name">{author.name}</div>
            <div className="tr-author-team" style={{ color: author.team.color }}>{author.team.name}</div>
          </div>
          <span className="tr-when">{t.day_label} · {t.time}</span>
        </Link>

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

        {t.effects?.length > 0 && (
          <div className="tr-effects">
            <div className="tr-effects-h">Effets sur cette course</div>
            {t.effects.map((e, i) => (
              <div key={i} className={`tr-effect ${e.tone}`}>
                <span className="tr-effect-ic">{e.emoji}</span>
                <div>
                  <div className="tr-effect-l">{e.label}</div>
                  <div className="tr-effect-d">{e.detail}</div>
                </div>
              </div>
            ))}
          </div>
        )}

        {t.description && <p className="tr-desc">{t.description}</p>}

        {t.photo_url && (
          <img className="tr-photo" src={t.photo_url} alt={`Photo de la sortie ${t.title}`} loading="lazy" />
        )}
      </main>

      <BottomNav />
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
