import { Head, Link, router, usePage } from '@inertiajs/react'
import { useState } from 'react'

const emojiFor = (name = '') => /citro|zeste|lemon/i.test(name) ? '🍋' : '🍓'
const itemEmoji = (t) => ({ shield: '🛡️', trap: '🐺', back_wind: '🌬️', booster: '✖️' }[t] || '🎒')

export default function Combat({ balls, multiplier, my_team, foe_team, items }) {
  const { flash } = usePage().props
  const [floats, setFloats] = useState([])
  const foe = foe_team?.monster
  const dmg = Math.round(10 * multiplier)

  const act = (action_type, item_id = null) => {
    if (action_type === 'attack' && foe && !foe.protected) {
      const id = Date.now() + Math.random()
      setFloats((f) => [...f, { id }])
      setTimeout(() => setFloats((f) => f.filter((x) => x.id !== id)), 1200)
    }
    router.post('/actions', { action_type, item_id }, { preserveScroll: true })
  }

  return (
    <div className="shell">
      <Head title="Combat" />
      <div className="subhead">
        <Link href="/" className="back">←</Link>
        <div className="ti">⚔️ Combat</div>
        <span className="curr" style={{ marginLeft: 'auto' }}>🍑 {balls}</span>
      </div>

      {flash?.notice && <div className="flash ok" style={{ margin: '10px 14px 0' }}>{flash.notice}</div>}
      {flash?.alert && <div className="flash err" style={{ margin: '10px 14px 0' }}>{flash.alert}</div>}

      {foe ? (
        <>
          <div className="cbt-top">
            <div className="cbt-enemy-name">{emojiFor(foe.name)} {foe.name}{foe.protected ? ' 🛡️' : ''}</div>
            <div className="bigbar"><i className="crit" style={{ width: `${foe.percent}%` }} /></div>
            <div className="hp-num" style={{ color: 'var(--crit)' }}>{foe.hp} / {foe.max_hp} PV</div>
          </div>
          <div className="arena-scene">
            {floats.map((f) => <div key={f.id} className="dmg">-{dmg}</div>)}
            <div className="foe-mon">{emojiFor(foe.name)}</div>
            {my_team?.monster && <div className="my-corner">{emojiFor(my_team.name)}</div>}
          </div>
        </>
      ) : (
        <div className="arena-scene"><p style={{ color: 'var(--muted)' }}>Pas encore d'adversaire.</p></div>
      )}

      <div className="act-gems">
        <button className="gem-btn" onClick={() => act('attack')} disabled={balls < 1}>
          <span className="e">⚡</span><span className="c">1 🍑</span>
        </button>
        <button className="gem-btn heal" onClick={() => act('heal')} disabled={balls < 2}>
          <span className="e">💚</span><span className="c">2 🍑</span>
        </button>
        {items.slice(0, 2).map((it) => (
          <button key={it.id} className="gem-btn item" onClick={() => act('use_item', it.id)}>
            <span className="e">{itemEmoji(it.effect_type)}</span><span className="c">objet</span>
          </button>
        ))}
      </div>
    </div>
  )
}
