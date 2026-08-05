import { Head, Link } from '@inertiajs/react'
import { useState } from 'react'
import BottomNav from '../components/BottomNav'
import PlayerAvatar from '../components/PlayerAvatar'
import Hud from '../components/Hud'

const ordinal = (n) => (n === 1 ? '1er' : `${n}e`)
const medal = (rank) => ({ 1: '🥇', 2: '🥈', 3: '🥉' }[rank] || null)

export default function Ligue({ month, overall, last_winner, balls }) {
  const [tab, setTab] = useState('month')
  const board = tab === 'month' ? month : overall

  return (
    <div className="shell">
      <Head title="Classement" />
      <Hud />

      <div className="subhead">
        <Link href="/" className="back">←</Link>
        <div className="ti">🏅 Classement</div>
        <span className="curr" style={{ marginLeft: 'auto' }}>🍑 {balls}</span>
      </div>

      <div className="chat-tabs">
        <button className={`chat-tab ${tab === 'month' ? 'on' : ''}`} onClick={() => setTab('month')}>
          📅 Du mois
        </button>
        <button className={`chat-tab ${tab === 'overall' ? 'on' : ''}`} onClick={() => setTab('overall')}>
          🏆 Général
        </button>
      </div>

      <main className="body">
        <div className="lg-card">
          <div className="lg-meta">
            <div className="lg-title">{board.label}</div>
            <div className="lg-sub">
              {board.me
                ? `${ordinal(board.me.rank)} sur ${board.total} · ${board.me.score} 🍑`
                : `${board.total} joueurs`}
            </div>
          </div>
          {tab === 'month' && (
            <div className="lg-clock">
              <div className="d">{month.days_left}</div>
              <div className="l">{month.days_left > 1 ? 'jours' : 'jour'}</div>
            </div>
          )}
        </div>

        {tab === 'month' && (
          <div className="lg-prize">
            🎁 Le 1er du mois gagne un cosmétique à la fin du mois.
            {last_winner && (
              <span className="lg-prev">
                Dernier vainqueur : <b>{last_winner.name}</b> ({last_winner.period})
                {last_winner.cosmetic
                  ? ` — ${last_winner.cosmetic.emoji || '🎁'} ${last_winner.cosmetic.name}`
                  : ` — ${last_winner.diamonds} 💎`}
              </span>
            )}
          </div>
        )}

        {board.rows.length === 0
          ? <p className="lg-empty">Personne au classement pour l'instant.</p>
          : <ol className="lg-list">
              {board.rows.map((row) => <li key={row.id}><Standing row={row} /></li>)}
            </ol>}

        <p className="lg-rules">
          1 km couru = 1 🍑 (max 10 par sortie). Le classement du mois repart de zéro le 1er ;
          le général cumule depuis le début de la partie.
        </p>
      </main>

      <BottomNav active="ligue" />
    </div>
  )
}

function Standing({ row }) {
  return (
    <Link href={`/joueurs/${row.id}`} className={`lg-row ${row.me ? 'me' : ''} ${row.rank <= 3 ? 'podium' : ''}`}>
      <span className="lg-rank">{medal(row.rank) || row.rank}</span>
      <PlayerAvatar avatar={row.avatar} size={34} />
      <span className="lg-name">
        {row.name}{row.me && <b> · toi</b>}
        <span className="lg-team" style={{ color: row.team.color }}>{row.team.name}</span>
      </span>
      <span className="lg-score">
        {row.score} 🍑
        <span className="lg-km">{row.km} km · {row.trainings} sortie{row.trainings > 1 ? 's' : ''}</span>
      </span>
    </Link>
  )
}
