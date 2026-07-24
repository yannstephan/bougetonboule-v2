import { Head, Link, router, usePage } from '@inertiajs/react'
import PlayerAvatar from '../components/PlayerAvatar'

const csrf = () =>
  (typeof document !== 'undefined' && document.querySelector('meta[name=csrf-token]')?.content) || ''

const slotLabel = { base: 'Base', hat: 'Chapeau', eyes: 'Yeux', outfit: 'Tenue', aura: 'Aura' }

export default function Avatar({ avatar, base_colors, body_styles, cosmetics, slots, has_team }) {
  const { flash } = usePage().props

  const save = (payload) =>
    router.patch('/avatar', { ...payload, authenticity_token: csrf() }, { preserveScroll: true })

  const toggle = (c) =>
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
          <PlayerAvatar avatar={avatar} size={120} />
        </div>

        <section className="av-sec">
          <h2>Personnage</h2>
          <div className="av-grid">
            {body_styles.map((s) => (
              <button key={s.key} className={`av-chip ${avatar.face === s.emoji ? 'on' : ''}`}
                      onClick={() => save({ body_style: s.key })}>
                <span className="e">{s.emoji}</span>
              </button>
            ))}
          </div>
        </section>

        <section className="av-sec">
          <h2>Couleur</h2>
          <div className="av-grid">
            {base_colors.map((c) => (
              <button key={c} className={`av-chip color ${avatar.color === c ? 'on' : ''}`}
                      style={{ background: `var(--${c})` }} aria-label={c}
                      onClick={() => save({ base_color: c })} />
            ))}
          </div>
        </section>

        <section className="av-sec">
          <h2>Cosmétiques</h2>
          {bySlot.length === 0
            ? <p className="av-empty">
                Tu n'as pas encore de cosmétique. Finis 1er du classement du mois pour en gagner un.
              </p>
            : bySlot.map(([slot, list]) => (
                <div key={slot} className="av-slot">
                  <div className="av-slot-name">{slotLabel[slot] || slot}</div>
                  <div className="av-grid">
                    {list.map((c) => (
                      <button key={c.id} className={`av-chip ${c.rarity} ${c.equipped ? 'on' : ''}`}
                              title={c.name} onClick={() => toggle(c)}>
                        <span className="e">{c.emoji || '🎁'}</span>
                        <span className="n">{c.name}</span>
                      </button>
                    ))}
                  </div>
                </div>
              ))}
        </section>

        {!has_team && (
          <p className="av-empty">
            Tu n'es pas encore dans une partie : ton avatar est prêt, il te suivra dès que tu
            rejoindras une équipe.
          </p>
        )}

        <Link href="/" className="btn primary">C'est bon !</Link>
      </main>
    </div>
  )
}
