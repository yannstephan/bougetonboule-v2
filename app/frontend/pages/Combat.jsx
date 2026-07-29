import { Head, router } from '@inertiajs/react'
import { useState } from 'react'
import Monster from '../components/Monster'
import EffectBadges from '../components/EffectBadges'
import TargetPicker from '../components/TargetPicker'
import TeamPicker from '../components/TeamPicker'
import SubHeader from '../components/SubHeader'
import Flash from '../components/Flash'
import { familyEmoji, itemEmoji } from '../lib/labels'

export default function Combat({ balls, multiplier, heal_cost, my_team, foe_team, items, opponents }) {
  const [floats, setFloats] = useState([]) // nombres flottants { id, type:'dmg'|'heal', text }
  const [hitFoe, setHitFoe] = useState(false)   // monstre adverse encaisse un coup
  const [healMine, setHealMine] = useState(false) // mon monstre est soigné
  const [trapItem, setTrapItem] = useState(null)   // objet piège en attente d'une cible
  const [smokeItem, setSmokeItem] = useState(null) // fumigène en attente d'une équipe
  const foe = foe_team?.monster
  const mine = my_team?.monster
  const dmg = Math.round(10 * multiplier)
  // Si notre équipe est enfumée, mine.hp est masqué (null) : on affiche le soin théorique.
  const healAmt = mine && !mine.masked ? Math.min(dmg, mine.max_hp - mine.hp) : dmg

  const float = (type, text) => {
    const id = Date.now() + Math.random()
    setFloats((f) => [...f, { id, type, text }])
    setTimeout(() => setFloats((f) => f.filter((x) => x.id !== id)), 1100)
  }

  const act = (action_type, item_id = null, target_id = null, target_team = null) => {
    if (action_type === 'attack' && foe && !foe.protected) {
      float('dmg', `-${dmg}`)
      setHitFoe(true)
      setTimeout(() => setHitFoe(false), 600)
    }
    if (action_type === 'heal' && mine && (mine.masked || mine.hp < mine.max_hp)) {
      float('heal', `+${healAmt}`)
      setHealMine(true)
      setTimeout(() => setHealMine(false), 750)
    }
    router.post('/actions', { action_type, item_id, target_id, target_team }, { preserveScroll: true })
  }

  const onItem = (it) => {
    if (it.effect_type === 'trap') return setTrapItem(it)
    if (it.effect_type === 'smoke') return setSmokeItem(it)
    act('use_item', it.id)
  }
  const pickTarget = (id) => { act('use_item', trapItem.id, id); setTrapItem(null) }
  const pickTeam = (which) => { act('use_item', smokeItem.id, null, which); setSmokeItem(null) }

  return (
    <div className="shell">
      <Head title="Combat" />
      <SubHeader title="⚔️ Combat">
        {multiplier > 1 && <span className="curr" title="Jauge de meute">🐾 ×{multiplier}</span>}
        <span className="curr" style={{ marginLeft: multiplier > 1 ? 0 : 'auto' }}>🍑 {balls}</span>
      </SubHeader>

      <Flash inset />

      {foe ? (
        <>
          <div className="cbt-top">
            <div className="cbt-enemy-name">{familyEmoji(foe_team?.fruit_family)} {foe.name}{foe.protected ? ' 🛡️' : ''}</div>
            <div className="bigbar">
              {foe.masked
                ? <i className="unknown" style={{ width: '100%' }} />
                : <i className="crit" style={{ width: `${foe.percent}%` }} />}
            </div>
            <div className="hp-num" style={{ color: 'var(--crit)' }}>
              {foe.masked ? '??? PV 🌫️' : `${foe.hp} / ${foe.max_hp} PV`}
            </div>
            <EffectBadges effects={foe_team?.effects} />
          </div>
          <div className="arena-scene">
            {floats.map((f) => <div key={f.id} className={f.type === 'heal' ? 'heal-float' : 'dmg'}>{f.text}</div>)}
            {hitFoe && <div className="burst">💥</div>}
            <Monster slug={foe.slug} name={foe.name} size={130}
                     className={`foe-mon-svg ${hitFoe ? 'impact' : ''}`} />
            {mine && (
              <>
                <Monster slug={mine.slug} name={mine.name} size={54}
                         className={`my-corner-svg ${healMine ? 'healpulse' : ''}`} />
                {healMine && <div className="heal-spark">✨</div>}
              </>
            )}
          </div>
        </>
      ) : (
        <div className="arena-scene"><p style={{ color: 'var(--muted)' }}>Pas encore d'adversaire.</p></div>
      )}

      {my_team?.effects?.length > 0 && (
        <div style={{ padding: '10px 14px 0' }}><EffectBadges effects={my_team.effects} label="Nous" /></div>
      )}

      <div className="act-gems">
        <button className="gem-btn" onClick={() => act('attack')} disabled={balls < 1}>
          <span className="e">⚡</span><span className="c">1 🍑</span>
        </button>
        <button className="gem-btn heal" onClick={() => act('heal')} disabled={balls < heal_cost}>
          <span className="e">💚</span><span className="c">{heal_cost} 🍑</span>
        </button>
        {items.slice(0, 2).map((it) => (
          <button key={it.id} className="gem-btn item" onClick={() => onItem(it)}>
            <span className="e">{itemEmoji(it.effect_type)}</span><span className="c">objet</span>
          </button>
        ))}
      </div>

      {trapItem && (
        <TargetPicker opponents={opponents} onPick={pickTarget} onClose={() => setTrapItem(null)} />
      )}
      {smokeItem && (
        <TeamPicker myTeam={my_team?.name} foeTeam={foe_team?.name} onPick={pickTeam} onClose={() => setSmokeItem(null)} />
      )}
    </div>
  )
}
