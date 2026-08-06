import { Head, router, usePage } from '@inertiajs/react'
import { useState } from 'react'
import Monster from '../components/Monster'
import EffectBadges from '../components/EffectBadges'
import TargetPicker from '../components/TargetPicker'
import MonsterPicker from '../components/MonsterPicker'
import Hud from '../components/Hud'
import BottomNav from '../components/BottomNav'

const familyEmoji = (family) => (family === 'rouges' ? '🍒' : '🌴')
const itemEmoji = (t) =>
  ({ shield: '🥣', trap: '🐺', back_wind: '🌬️', face_wind: '🌪️', smoke: '🍦', wooden_leg: '🦿' }[t] || '🎒')

export default function Combat({ balls, multiplier, heal_cost, my_team, foe_team, items, opponents }) {
  const { flash } = usePage().props
  const [floats, setFloats] = useState([]) // nombres flottants { id, type:'dmg'|'heal', text }
  const [hitFoe, setHitFoe] = useState(false)   // monstre adverse encaisse un coup
  const [healMine, setHealMine] = useState(false) // mon monstre est soigné
  const [trapItem, setTrapItem] = useState(null)   // objet piège en attente d'une cible
  const [smokeItem, setSmokeItem] = useState(null) // chantilly en attente d'un monstre à barbouiller
  const foe = foe_team?.monster
  const mine = my_team?.monster
  const dmg = Math.round(10 * multiplier)
  // Si notre équipe est barbouillée, mine.hp est masqué (null) : on affiche le soin théorique.
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
  const pickMask = (which) => { act('use_item', smokeItem.id, null, which); setSmokeItem(null) }

  return (
    <div className="shell">
      <Head title="Combat" />
      <Hud />

      {flash?.notice && <div className="flash ok" style={{ margin: '10px 14px 0' }}>{flash.notice}</div>}
      {flash?.alert && <div className="flash err" style={{ margin: '10px 14px 0' }}>{flash.alert}</div>}

      {foe ? (
        <>
          <div className="cbt-top">
            <div className="cbt-enemy-name">{familyEmoji(foe_team?.fruit_family)} {foe.name}{foe.protected ? ' 🥣' : ''}</div>
            <div className="bigbar">
              {foe.masked
                ? <i className="unknown" style={{ width: '100%' }} />
                : <i className="crit" style={{ width: `${foe.percent}%` }} />}
            </div>
            <div className="hp-num" style={{ color: 'var(--crit)' }}>
              {foe.masked ? '??? PV 🍦' : `${foe.hp} / ${foe.max_hp} PV`}
            </div>
            <EffectBadges effects={foe_team?.effects} />
          </div>
          <div className="arena-scene">
            {floats.map((f) => <div key={f.id} className={f.type === 'heal' ? 'heal-float' : 'dmg'}>{f.text}</div>)}
            {hitFoe && <div className="burst">💥</div>}
            <Monster slug={foe.slug} name={foe.name} size={130}
                     wear={foe.wear} creamed={foe.masked} shielded={foe.protected}
                     defeated={foe.state === 'defeated'}
                     className={`foe-mon-svg ${hitFoe ? 'impact' : ''}`} />
            {mine && (
              <>
                <Monster slug={mine.slug} name={mine.name} size={54}
                         wear={mine.wear} creamed={mine.masked} shielded={mine.protected}
                         defeated={mine.state === 'defeated'}
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
          <button key={it.id} className="gem-btn item" onClick={() => onItem(it)}
                  disabled={it.active} title={it.active ? 'Déjà en cours' : undefined}>
            <span className="e">{itemEmoji(it.effect_type)}</span>
            <span className="c">{it.active ? 'en cours' : 'objet'}</span>
          </button>
        ))}
      </div>

      {trapItem && (
        <TargetPicker opponents={opponents} onPick={pickTarget} onClose={() => setTrapItem(null)} />
      )}
      {smokeItem && (
        <MonsterPicker myMonster={my_team?.monster?.name} foeMonster={foe_team?.monster?.name}
                       foeTeam={foe_team?.name} onPick={pickMask} onClose={() => setSmokeItem(null)} />
      )}
      <BottomNav />
    </div>
  )
}
