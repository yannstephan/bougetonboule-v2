import { Head, Link, usePage } from '@inertiajs/react'
import BottomNav from '../components/BottomNav'
import PlayerAvatar from '../components/PlayerAvatar'
import Monster from '../components/Monster'

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
        <Link href="/notifications" className="bell bell-badge">🔔{unread > 0 && <span className="b">{unread}</span>}</Link>
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
      {m.special_day && (
        <div className="specialday">
          🎄 Jour spécial · {m.special_day.name}
          <span className="x2">🍑 ×{m.special_day.multiplier}</span>
        </div>
      )}
      <div className="stage">
        <Monster slug={mine.monster?.slug} name={mine.monster?.name} size={130} className="stage-mon" />
        <div className="mname">{mine.monster?.name || mine.name}</div>
        <div className="mtag">{mine.name}</div>
      </div>
      <div className="vs-mini">
        <div className="side">
          <div className="row"><b>{familyEmoji(mine.fruit_family)} Nous</b><span>{mine.monster?.hp ?? '–'}</span></div>
          <div className="minibar"><i className="good" style={{ width: `${mine.monster?.percent ?? 0}%` }} /></div>
        </div>
        <span className="vlabel">VS</span>
        <div className="side">
          <div className="row"><span>{foe?.monster?.hp ?? '–'}</span><b>{familyEmoji(foe?.fruit_family)} Eux</b></div>
          <div className="minibar"><i className="crit" style={{ width: `${foe?.monster?.percent ?? 0}%` }} /></div>
        </div>
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
