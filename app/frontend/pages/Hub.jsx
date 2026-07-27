import { Head, Link, usePage } from '@inertiajs/react'
import BottomNav from '../components/BottomNav'
import PlayerAvatar from '../components/PlayerAvatar'
import Monster from '../components/Monster'
import EffectBadges from '../components/EffectBadges'
import Countdown from '../components/Countdown'

const familyEmoji = (family) => (family === 'rouges' ? '🍒' : '🌴')

export default function Hub({ membership }) {
  const { auth } = usePage().props
  const user = auth.user
  const unread = user?.unread_count || 0

  return (
    <div className="shell">
      <Head title="Bouge Ton Boule" />
      <header className="hud">
        <Link href="/avatar" className="hud-avatar" title="Personnaliser mon avatar">
          <PlayerAvatar avatar={user?.avatar} size={38} />
        </Link>
        <span className="curr">🍑 {membership ? membership.balls : 0}</span>
        <span className="curr">💎 {user?.diamonds ?? 0}</span>
        <Link href="/faq" className="bell" title="Règles du jeu">📖</Link>
        <Link href="/notifications" className="bell bell-badge" style={{ marginLeft: 0 }}>🔔{unread > 0 && <span className="b">{unread}</span>}</Link>
      </header>

      {membership ? <GameView m={membership} /> : <Onboarding user={user} />}

      <BottomNav active="hub" />
    </div>
  )
}

function GameView({ m }) {
  const mine = m.my_team
  const foe = m.opponent
  return (
    <main className="body">
      {m.event?.race_at && (
        <Countdown raceAt={m.event.race_at} startAt={m.event.starts_at} name={m.event.name} location={m.event.location} />
      )}
      {m.special_day && (
        <div className="specialday">
          🎄 Jour spécial · {m.special_day.name}
          <span className="x2">🍑 ×{m.special_day.multiplier}</span>
        </div>
      )}
      <div className="boards">
        <TeamBoard team={mine} mine />
        <div className="boards-vs"><span>VS</span></div>
        {foe ? <TeamBoard team={foe} /> : <div className="board board-empty">En attente d'un adversaire…</div>}
      </div>

      <Link href="/combat" className="btn combat">⚔️ COMBATTRE</Link>
      <div className="tiles">
        <div className="tile"><span className="ic">🔥</span><div><div className="tn">Série hebdo</div><div className="td">{m.weekly_streak} sem.</div></div></div>
        <div className="tile"><span className="ic">🎁</span><div><div className="tn">Coffres</div><div className="td">{m.sealed_chests} à ouvrir</div></div></div>
        <Link href="/ligue" className="tile"><span className="ic">🏅</span><div><div className="tn">Classement</div><div className="td">{m.month_rank ? `${m.month_rank}e ce mois-ci` : 'Cours pour entrer'}</div></div></Link>
        <Link href="/avatar" className="tile"><span className="ic">🎨</span><div><div className="tn">Mon avatar</div><div className="td">Personnaliser</div></div></Link>
      </div>
    </main>
  )
}

// État de santé → couleur de la barre de PV (même code pour les deux équipes, pas de « nous/eux »).
const hpClass = (state) => ({ healthy: 'good', hurt: 'warn', critical: 'crit', defeated: 'crit' }[state] || 'good')

function TeamBoard({ team, mine = false }) {
  const mon = team.monster
  return (
    <div className={`board ${mine ? 'mine' : ''}`} style={mine ? { borderColor: team.color } : undefined}>
      <div className="board-top">
        <Monster slug={mon?.slug} name={mon?.name} size={64} />
        <div className="board-id">
          <div className="board-team">{familyEmoji(team.fruit_family)} {team.name}{mine && <span className="board-you">toi</span>}</div>
          <div className="board-mon">{mon?.name}</div>
        </div>
      </div>
      <div className="board-hp">
        <div className="bigbar"><i className={hpClass(mon?.state)} style={{ width: `${mon?.percent ?? 0}%` }} /></div>
        <div className="board-hpnum">{mon?.hp ?? '–'} / {mon?.max_hp ?? '–'} PV</div>
      </div>
      <EffectBadges effects={team.effects} />
    </div>
  )
}

function Onboarding({ user }) {
  return (
    <main className="body onboard">
      <div className="big">🍑</div>
      <h1>Salut {user?.firstname} !</h1>
      <p>Tu n'es pas encore dans une partie active. Connecte ton compte Strava pour que tes courses comptent.</p>
      {!user?.strava_connected
        ? <a className="btn strava" href="/strava/connect">◎ Connecter Strava</a>
        : <p style={{ color: 'var(--good)', fontWeight: 700 }}>✅ Strava connecté — en attente d'une partie.</p>}
    </main>
  )
}
