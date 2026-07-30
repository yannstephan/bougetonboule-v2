import { Head, Link, router, usePage } from '@inertiajs/react'
import { useState } from 'react'
import FruitAvatar from '../components/FruitAvatar'
import PlayerAvatar from '../components/PlayerAvatar'
import { CosmeticIcon } from '../components/cosmeticArt'

const csrf = () =>
  (typeof document !== 'undefined' && document.querySelector('meta[name=csrf-token]')?.content) || ''

// Un onglet par emplacement, plus le fruit lui-même. L'icône sert de repère visuel dans la
// barre : on ne lit plus une liste de 45 pièces, on ouvre un rayon.
const TABS = {
  fruit: { label: 'Fruit', icon: '🍓' },
  hat: { label: 'Chapeau', icon: '🎩' },
  eyes: { label: 'Lunettes', icon: '👓' },
  neck: { label: 'Cou', icon: '🧣' },
  hands: { label: 'Bras', icon: '🦾' },
  shoes: { label: 'Chaussures', icon: '👟' },
  sidekick: { label: 'Accessoire', icon: '🐕' },
  aura: { label: 'Aura', icon: '✨' },
}

export default function Avatar({ has_team, strava_connected, is_admin, team, fruits, current_fruit, avatar, cosmetics, slots }) {
  const { flash } = usePage().props

  const pickFruit = (key) =>
    router.patch('/avatar', { fruit: key, authenticity_token: csrf() }, { preserveScroll: true })

  const toggleCosmetic = (c) =>
    router.post('/avatar/equip',
      { cosmetic_id: c.id, equipped: !c.equipped, authenticity_token: csrf() },
      { preserveScroll: true })

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

  const bySlot = slots
    .map((slot) => [slot, cosmetics.filter((c) => c.slot === slot)])
    .filter(([, list]) => list.length > 0)

  // L'aperçu et les onglets restent collés en haut : on voit le résultat pendant qu'on
  // choisit, au lieu de scroller entre la pièce et l'avatar.
  const [tab, setTab] = useState('hat')
  const tabs = ['fruit', ...slots]
  const active = tabs.includes(tab) ? tab : 'fruit'
  const inSlot = (slot) => cosmetics.filter((c) => c.slot === slot)
  const equippedIn = (slot) => inSlot(slot).find((c) => c.equipped)

  return (
    <div className="shell">
      <Head title="Mon avatar" />
      <div className="subhead">
        <Link href="/" className="back">←</Link>
        <div className="ti">🎨 Mon avatar</div>
      </div>

      <main className="body">
        {flash?.notice && <div className="flash ok">{flash.notice}</div>}
        {flash?.alert && <div className="flash err">{flash.alert}</div>}

        {!has_team ? (
          <>
            <div className="av-stage"><PlayerAvatar avatar={avatar} size={128} /></div>
            <NoTeam />
          </>
        ) : (
          <>
            <div className="av-sticky">
              <div className="av-stage"><PlayerAvatar avatar={avatar} size={132} /></div>
              <div className="av-tabs">
                {tabs.map((key) => (
                  <button key={key} className={`av-tab ${active === key ? 'on' : ''}`}
                          onClick={() => setTab(key)}>
                    <span className="ic">{TABS[key]?.icon || '🎁'}</span>
                    <span className="tn">{TABS[key]?.label || key}</span>
                    {key !== 'fruit' && equippedIn(key) && <span className="dot" />}
                  </button>
                ))}
              </div>
            </div>

            {active === 'fruit' ? (
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
            ) : (
              <SlotRack slot={active} list={inSlot(active)} onToggle={toggleCosmetic} />
            )}
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

// Le rayon d'un emplacement : les pièces possédées, plus une case « Retirer » quand
// quelque chose est équipé — sinon il faut retrouver la pièce portée pour l'enlever.
function SlotRack({ slot, list, onToggle }) {
  const worn = list.find((c) => c.equipped)

  if (list.length === 0) {
    return (
      <section className="av-sec">
        <h2>{TABS[slot]?.label || slot}</h2>
        <p className="av-empty">
          Rien dans cet emplacement pour l'instant. Les cosmétiques s'achètent en 💎 à la
          boutique, ou se gagnent (série hebdo, coffres, 1er du classement du mois).
        </p>
      </section>
    )
  }

  return (
    <section className="av-sec">
      <h2>{TABS[slot]?.label || slot} · {list.length}</h2>
      <div className="av-rack">
        {worn && (
          <button className="av-card bare" onClick={() => onToggle(worn)}>
            <span className="e">🚫</span>
            <span className="n">Retirer</span>
          </button>
        )}
        {list.map((c) => (
          <button key={c.id} className={`av-card ${c.rarity} ${c.equipped ? 'on' : ''}`}
                  onClick={() => onToggle(c)}>
            <CosmeticIcon art={c.art} emoji={c.emoji} className="e" />
            <span className="n">{c.name}</span>
            {c.equipped && <span className="tick">✓</span>}
          </button>
        ))}
      </div>
    </section>
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
    </div>
  )
}
