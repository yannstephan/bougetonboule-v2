import { Head, Link, router, usePage } from '@inertiajs/react'
import BottomNav from '../components/BottomNav'
import Monster from '../components/Monster'
import EffectBadges from '../components/EffectBadges'
import Countdown from '../components/Countdown'
import InstallHint from '../components/InstallHint'
import StreakPass from '../components/StreakPass'
import Hud from '../components/Hud'
import { familyEmoji } from '../lib/gameIcons'
import { csrf } from '../lib/csrf'

// Ce qu'annonce la tuile « Mon sac ». Un coffre à ouvrir passe devant tout le reste.
const bagLine = (chests, items) => {
  if (chests > 0) return `🎁 ${chests} coffre${chests > 1 ? 's' : ''} à ouvrir !`
  if (items > 0) return `${items} objet${items > 1 ? 's' : ''} à utiliser`
  return 'Vide — passe à la boutique'
}

export default function Hub({ membership }) {
  const user = usePage().props.auth.user

  return (
    <div className="shell">
      <Head title="Bouge Ton Boule" />
      <Hud />

      {membership ? <GameView m={membership} /> : <Onboarding user={user} />}

      <BottomNav />
    </div>
  )
}

function GameView({ m }) {
  const chests = usePage().props.inventory_alert || 0
  const mine = m.my_team
  const foe = m.opponent
  const finished = m.game?.status === 'finished'
  return (
    <main className="body">
      <InstallHint />
      {finished && (
        <div className="specialday" style={{ background: 'var(--violet)' }}>
          🏁 Partie terminée · {m.game.winner ? `Victoire des ${m.game.winner} 🏆` : 'Égalité parfaite 🤝'}
        </div>
      )}
      {!finished && m.event?.race_at && (
        <Countdown raceAt={m.event.race_at} startAt={m.event.starts_at} name={m.event.name} location={m.event.location} />
      )}
      {!finished && m.special_day && (
        <div className="specialday">
          🎉 Jour spécial · {m.special_day.name}
          <span className="x2">🍑 ×{m.special_day.multiplier}</span>
        </div>
      )}
      <div className="arena">
        <TeamSide team={mine} mine />
        <div className="arena-mid">
          <span className="arena-rule" />
          <span className="arena-vs"><b>⚡</b><i>VS</i></span>
          <span className="arena-rule" />
        </div>
        {foe
          ? <TeamSide team={foe} />
          : <div className="arena-side foe arena-wait">En attente d'un adversaire…</div>}
      </div>

      {!finished && <Link href="/combat" className="btn combat">⚔️ COMBATTRE</Link>}
      <TeamTally mine={mine} foe={foe} />
      <RunFeed mine={mine} foe={foe} />
      <StreakPass streak={m.streak} />
      <div className="tiles">
        <Link href="/ligue" className="tile" style={{ gridColumn: '1 / -1' }}><span className="ic">🏅</span><div><div className="tn">Classement</div><div className="td">{m.month_rank ? `${m.month_rank}e ce mois-ci` : 'Cours pour entrer'}</div></div></Link>
        <Link href="/sac" className={`tile ${chests > 0 ? 'tile-alert' : ''}`} style={{ gridColumn: '1 / -1' }}>
          <span className="ic">🎒</span>
          <div>
            <div className="tn">Mon sac</div>
            <div className="td">{bagLine(chests, m.bag_count)}</div>
          </div>
        </Link>
      </div>
    </main>
  )
}

// État de santé → couleur de la barre de PV (même code pour les deux équipes, pas de « nous/eux »).
const hpClass = (state) => ({ healthy: 'good', hurt: 'warn', critical: 'crit', defeated: 'crit' }[state] || 'good')

// Le total de PV en version courte (10000 → « 10k ») : les deux camps tiennent côte à côte,
// et c'est le nombre de PV restants qui compte, pas le maximum qu'on connaît par cœur.
const shortHp = (n) => (n == null ? '–' : n >= 1000 && n % 1000 === 0 ? `${n / 1000}k` : String(n))

// Un camp de l'arène, empilé dans l'ordre où on le lit : qui c'est, puis LE MONSTRE en grand,
// puis sa vie, puis ses effets. Le monstre occupe toute la largeur du camp — c'est la pièce
// maîtresse de l'écran, pas une vignette d'identité. Le camp adverse est le miroir du sien
// (textes et pastilles alignés vers le bord), les deux se faisant face autour du ⚡.
function TeamSide({ team, mine = false }) {
  const mon = team.monster
  return (
    <div className={`arena-side ${mine ? 'mine' : 'foe'}`}>
      <span className={`arena-tag ${mine ? 'mine' : 'foe'}`}>{mine ? 'TOI' : 'ENNEMI'}</span>
      <div className="arena-names">
        <span className="arena-team">{familyEmoji(team.fruit_family)} {team.name}</span>
        <span className="arena-mon">{mon?.name}</span>
      </div>
      <span className="arena-face">
        <Monster slug={mon?.slug} name={mon?.name} size="100%"
                 wear={mon?.wear} creamed={mon?.masked} shielded={mon?.protected}
                 defeated={mon?.state === 'defeated'} />
      </span>
      <div className="arena-hp">
        <div className="arena-hp-top">
          <span className="l">PV</span>
          <span className="n">{mon?.masked ? '??? 🍦' : `${mon?.hp ?? '–'} / ${shortHp(mon?.max_hp)}`}</span>
        </div>
        <div className="bigbar">
          {mon?.masked
            ? <i className="unknown" style={{ width: '100%' }} />
            : <i className={hpClass(mon?.state)} style={{ width: `${mon?.percent ?? 0}%` }} />}
        </div>
      </div>
      <EffectBadges effects={team.effects} compact />
    </div>
  )
}

// Le suivi des deux équipes, dans la même grille gauche/droite que l'arène : les 🍑 gagnées en
// courant (la semaine, puis depuis le début) et la jauge de meute de la semaine en cours —
// combien de coéquipiers ont déjà fait leurs 8 km, sur combien, pour viser le palier du lundi.
function TeamTally({ mine, foe }) {
  if (!mine?.tally) return null

  return (
    <section className="feed">
      <h2 className="feed-title">Cette semaine</h2>
      <div className="feed-cols">
        <TallyColumn tally={mine.tally} mine />
        <span className="feed-rule" />
        {foe?.tally ? <TallyColumn tally={foe.tally} /> : <div className="feed-col foe" />}
      </div>
    </section>
  )
}

function TallyColumn({ tally, mine = false }) {
  const { pack } = tally
  const missing = Math.max(pack.needed - pack.runners, 0)
  const note = pack.maxed ? 'meute au maximum'
    : missing === 0 ? '✅ palier gagné lundi'
    : `encore ${missing} pour le palier`

  return (
    <div className={`feed-col ${mine ? 'mine' : 'foe'}`}>
      <div className="tally-line">
        <b className="tally-n">{tally.week_balls} 🍑</b>
        <span className="feed-meta">gagnées · {tally.total_balls} au total</span>
      </div>
      <div className="tally-line">
        <b className="tally-n">🐾 {pack.runners}/{pack.size}</b>
        <span className="feed-meta">ont couru {pack.km} km</span>
        <span className="tally-bar"><i style={{ width: `${Math.min(pack.runners / pack.needed, 1) * 100}%` }} /></span>
        <span className={`feed-meta ${missing === 0 && !pack.maxed ? 'tally-ok' : ''}`}>{note}</span>
      </div>
    </div>
  )
}

// Les dernières sorties des deux camps, dans la même grille gauche/droite que l'arène : on
// retrouve son équipe du même côté que son monstre, sans avoir à relire les noms.
function RunFeed({ mine, foe }) {
  if (!mine?.runs?.length && !foe?.runs?.length) return null

  return (
    <section className="feed">
      <h2 className="feed-title">Dernières sorties</h2>
      <div className="feed-cols">
        <RunColumn runs={mine?.runs} mine />
        <span className="feed-rule" />
        <RunColumn runs={foe?.runs} />
      </div>
    </section>
  )
}

function RunColumn({ runs = [], mine = false }) {
  if (runs.length === 0) {
    return <div className={`feed-col ${mine ? 'mine' : 'foe'}`}><p className="feed-empty">Personne n'a encore couru.</p></div>
  }

  return (
    <div className={`feed-col ${mine ? 'mine' : 'foe'}`}>
      {runs.map((r) => (
        <Link key={r.id} href={`/courses/${r.id}`} className="feed-run">
          <span className="feed-who">{r.who}</span>
          <span className="feed-meta">
            {r.day} · {String(r.km).replace('.', ',')} km
            {r.trapped
              ? <b className="trapped"> · 🐺 0 🍑</b>
              : <b> · +{r.balls} 🍑</b>}
          </span>
        </Link>
      ))}
    </div>
  )
}

function Onboarding({ user }) {
  const logout = () => {
    if (confirm('Se déconnecter de ce compte ?')) {
      router.delete('/logout', { data: { authenticity_token: csrf() } })
    }
  }

  return (
    <main className="body onboard">
      <InstallHint />
      <div className="big">🍑</div>
      {/* Le seul écran du jeu qui n'a encore rien à montrer, donc le seul où le jeu doit se
          présenter : le NOM en titre, sa promesse en une ligne, et le bonjour ensuite. */}
      <h1>Bouge Ton Boule</h1>
      <p className="onboard-claim">Chaque kilomètre couru fait pousser une boule 🍑 — et chaque boule frappe le monstre du clan adverse.</p>
      <p className="onboard-hi">Salut {user?.firstname} !</p>
      <p>Tu n'es pas encore dans une partie active. Connecte ton compte Strava pour que tes courses comptent.</p>
      {!user?.strava_connected
        ? <a className="btn strava" href="/strava/connect">◎ Connecter Strava</a>
        : <p style={{ color: 'var(--good)', fontWeight: 700 }}>✅ Strava connecté — en attente d'une partie.</p>}
      <button type="button" className="btn-logout" onClick={logout}>Se déconnecter</button>
    </main>
  )
}
