import { Head, Link, router, usePage } from '@inertiajs/react'
import FruitAvatar from '../components/FruitAvatar'
import PlayerAvatar from '../components/PlayerAvatar'
import Hud from '../components/Hud'
import BottomNav from '../components/BottomNav'

const csrf = () =>
  (typeof document !== 'undefined' && document.querySelector('meta[name=csrf-token]')?.content) || ''

// Le fruit-avatar et le compte. Les cosmétiques se rangent et s'équipent dans le sac
// (/sac, onglet 🎨) : un seul chemin pour habiller son fruit.
export default function Avatar({ has_team, strava_connected, is_admin, team, fruits, avatar }) {
  const { flash } = usePage().props

  const pickFruit = (key) =>
    router.patch('/avatar', { fruit: key, authenticity_token: csrf() }, { preserveScroll: true })

  const logout = () => {
    if (confirm('Se déconnecter de ce compte ?')) {
      router.delete('/logout', { data: { authenticity_token: csrf() } })
    }
  }

  const disconnectStrava = () => {
    if (confirm("Déconnecter ton compte Strava ? Tes nouvelles courses ne s'importeront plus.")) {
      router.delete('/strava/disconnect', { data: { authenticity_token: csrf() } })
    }
  }

  return (
    <div className="shell">
      <Head title="Mon avatar" />
      <Hud />

      <div className="subhead">
        <Link href="/" className="back">←</Link>
        <div className="ti">🎨 Mon avatar</div>
      </div>

      <main className="body">
        {flash?.notice && <div className="flash ok">{flash.notice}</div>}
        {flash?.alert && <div className="flash err">{flash.alert}</div>}

        <div className="av-stage"><PlayerAvatar avatar={avatar} size={132} /></div>

        {!has_team ? (
          <NoTeam />
        ) : (
          <>
            <Link href="/sac?tab=wardrobe" className="btn ghost">🎨 Habiller mon fruit (armoire du sac)</Link>

            <section className="av-sec">
              <h2>Ton fruit · {team.family_label}</h2>
              <p className="av-hint">
                Choisis le fruit qui te représente dans l'équipe {team.name}. Plusieurs joueurs
                peuvent porter le même — on t'indique qui l'a déjà pris.
              </p>
              <div className="fruit-grid">
                {fruits.map((f) => (
                  <button key={f.key} className={`fruit-pick ${f.mine ? 'on' : ''}`} onClick={() => pickFruit(f.key)}>
                    <FruitAvatar fruit={f.key} size={64} showCosmetics={false} />
                    <span className="fruit-name">{f.name}</span>
                    {f.taken_by.length > 0 && (
                      <span className="fruit-taken">déjà : {f.taken_by.join(', ')}</span>
                    )}
                  </button>
                ))}
              </div>
            </section>
          </>
        )}

        <section className="av-sec">
          <h2>Compte Strava</h2>
          {strava_connected ? (
            <div className="strava-row">
              <span className="strava-ok">◎ Strava connecté</span>
              <button type="button" className="strava-off" onClick={disconnectStrava}>Déconnecter</button>
            </div>
          ) : (
            <>
              <p className="av-hint">Connecte Strava pour que tes courses comptent automatiquement.</p>
              <a className="btn strava" href="/strava/connect">◎ Connecter Strava</a>
            </>
          )}
        </section>

        {is_admin && (
          <Link href="/admin" className="btn ghost">🛠️ Organisation de la partie</Link>
        )}

        <Link href="/" className="btn primary">C'est bon !</Link>
        <button type="button" className="btn-logout" onClick={logout}>Se déconnecter</button>
      </main>
    </div>
  )
}

function NoTeam() {
  return (
    <div className="av-empty" style={{ textAlign: 'center' }}>
      <p style={{ fontSize: 15, fontWeight: 700, color: 'var(--text)' }}>
        Tu n'es pas encore dans une équipe.
      </p>
      <p>
        Ton avatar se choisit une fois que tu as rejoint une partie : chaque équipe a sa propre
        famille de fruits (exotiques ou rouges). Reviens ici dès que tu es affecté·e à une équipe.
      </p>
      <BottomNav />
    </div>
  )
}
