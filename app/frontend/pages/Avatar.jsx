import { Head, Link, router, usePage } from '@inertiajs/react'
import FruitAvatar from '../components/FruitAvatar'
import PlayerAvatar from '../components/PlayerAvatar'

const csrf = () =>
  (typeof document !== 'undefined' && document.querySelector('meta[name=csrf-token]')?.content) || ''

const slotLabel = { base: 'Base', hat: 'Chapeau', eyes: 'Yeux', outfit: 'Tenue',
  arms: 'Bras', legs: 'Jambes', aura: 'Aura' }

export default function Avatar({ has_team, team, fruits, current_fruit, avatar, cosmetics, slots }) {
  const { flash } = usePage().props

  const pickFruit = (key) =>
    router.patch('/avatar', { fruit: key, authenticity_token: csrf() }, { preserveScroll: true })

  const toggleCosmetic = (c) =>
    router.post('/avatar/equip',
      { cosmetic_id: c.id, equipped: !c.equipped, authenticity_token: csrf() },
      { preserveScroll: true })

  const bySlot = slots
    .map((slot) => [slot, cosmetics.filter((c) => c.slot === slot)])
    .filter(([, list]) => list.length > 0)

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

        <div className="av-stage">
          <PlayerAvatar avatar={avatar} size={128} />
        </div>

        {!has_team ? (
          <NoTeam />
        ) : (
          <>
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

            <section className="av-sec">
              <h2>Cosmétiques</h2>
              {bySlot.length === 0 ? (
                <p className="av-empty">
                  Tu n'as pas encore de cosmétique. Finis 1er du classement du mois pour en gagner un.
                </p>
              ) : (
                bySlot.map(([slot, list]) => (
                  <div key={slot} className="av-slot">
                    <div className="av-slot-name">{slotLabel[slot] || slot}</div>
                    <div className="av-grid">
                      {list.map((c) => (
                        <button key={c.id} className={`av-chip ${c.rarity} ${c.equipped ? 'on' : ''}`}
                                title={c.name} onClick={() => toggleCosmetic(c)}>
                          <span className="e">{c.emoji || '🎁'}</span>
                          <span className="n">{c.name}</span>
                        </button>
                      ))}
                    </div>
                  </div>
                ))
              )}
            </section>
          </>
        )}

        <Link href="/" className="btn primary">C'est bon !</Link>
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
    </div>
  )
}
