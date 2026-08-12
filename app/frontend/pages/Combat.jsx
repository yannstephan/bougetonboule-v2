import { Head, Link, router, usePage } from '@inertiajs/react'
import { useState } from 'react'
import Monster from '../components/Monster'
import EffectBadges from '../components/EffectBadges'
import TargetPicker from '../components/TargetPicker'
import MonsterPicker from '../components/MonsterPicker'
import ItemPicker from '../components/ItemPicker'
import Hud from '../components/Hud'
import BottomNav from '../components/BottomNav'
import { familyEmoji } from '../lib/gameIcons'

// L'écran de combat est monté comme un COMBAT POKÉMON, et ce n'est pas une citation
// gratuite : c'est la mise en page qui répond le mieux à la question « où en est-on ? ».
//
//   ┌─────────────────────────────┐
//   │ [carte ennemi]      🌿      │   l'adversaire est LOIN : plus haut, plus petit
//   │                    ennemi   │
//   │   NOUS                      │   nous sommes AU PREMIER PLAN : plus bas, plus grand
//   │   🥥            [ma carte]  │
//   ├─────────────────────────────┤
//   │ Que faites-vous ?      🍑   │   le menu de commandes, comme la boîte de dialogue
//   │ [ATTAQUER] [SOIGNER]        │
//   │ [POWER-UPS] [RETOUR]        │
//   └─────────────────────────────┘
//
// Deux choses en découlent, et ce sont elles qui font le rendu :
//   - la PROFONDEUR. L'ennemi est servi plus petit que nous et posé plus haut sur le terrain :
//     c'est la seule façon de dire « il est en face » sans dessiner de décor. Chacun a son
//     ombre elliptique au sol, qui l'ancre au terrain au lieu de le laisser flotter.
//   - la DIAGONALE. Carte à gauche / monstre à droite en haut, l'inverse en bas. L'œil
//     descend en zigzag et ne confond jamais les deux camps, même barbouillés de chantilly.
//
// ⚠️ Un écart assumé avec le modèle : Pokémon cache les PV chiffrés de l'adversaire. Ici on
// les montre — savoir s'il reste 300 ou 3 000 PV décide de tout un tour de jeu, et c'est déjà
// la chantilly qui gère le brouillard de guerre. Ce qui reste caché reste caché.
export default function Combat({
  balls, wallet_cap: walletCap, multiplier, attack_cost: attackCost, heal_cost: healCost,
  crit_fail_chance: critFail, my_team: myTeam, foe_team: foeTeam, items, opponents,
}) {
  const { flash } = usePage().props
  const [floats, setFloats] = useState([]) // nombres flottants { id, type:'dmg'|'heal', text }
  const [hitFoe, setHitFoe] = useState(false)   // monstre adverse encaisse un coup
  const [healMine, setHealMine] = useState(false) // mon monstre est soigné
  const [picking, setPicking] = useState(false)    // feuille des power-ups
  const [trapItem, setTrapItem] = useState(null)   // objet piège en attente d'une cible
  const [smokeItem, setSmokeItem] = useState(null) // chantilly en attente d'un monstre à barbouiller
  const foe = foeTeam?.monster
  const mine = myTeam?.monster
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
    setPicking(false)
    if (it.effect_type === 'trap') return setTrapItem(it)
    if (it.effect_type === 'smoke') return setSmokeItem(it)
    act('use_item', it.id)
  }
  const pickTarget = (id) => { act('use_item', trapItem.id, id); setTrapItem(null) }
  const pickMask = (which) => { act('use_item', smokeItem.id, null, which); setSmokeItem(null) }

  const usable = items.filter((it) => !it.active).length

  return (
    <div className="shell">
      <Head title="Combat" />
      <Hud />

      {flash?.notice && <div className="flash ok" style={{ margin: '10px 14px 0' }}>{flash.notice}</div>}
      {flash?.alert && <div className="flash err" style={{ margin: '10px 14px 0' }}>{flash.alert}</div>}

      {foe ? (
        <div className="pkm-field">
          {floats.map((f) => (
            <div key={f.id} className={f.type === 'heal' ? 'heal-float' : 'dmg'}>{f.text}</div>
          ))}

          {/* Le camp d'EN FACE : carte à gauche, monstre à droite et plus petit. */}
          <div className="pkm-row foe">
            <Card side="foe" team={foeTeam} monster={foe} />
            <div className="pkm-slot">
              {hitFoe && <div className="burst">💥</div>}
              <Monster slug={foe.slug} name={foe.name} size="100%"
                       wear={foe.wear} creamed={foe.masked} shielded={foe.protected}
                       defeated={foe.state === 'defeated'}
                       className={`pkm-mon ${hitFoe ? 'impact' : ''}`} />
              <span className="pkm-shadow" />
            </div>
          </div>

          {/* Le NÔTRE : monstre à gauche et plus grand, carte à droite. */}
          {mine && (
            <div className="pkm-row mine">
              <div className="pkm-slot">
                {healMine && <div className="heal-spark">✨</div>}
                <Monster slug={mine.slug} name={mine.name} size="100%"
                         wear={mine.wear} creamed={mine.masked} shielded={mine.protected}
                         defeated={mine.state === 'defeated'}
                         className={`pkm-mon ${healMine ? 'healpulse' : ''}`} />
                <span className="pkm-shadow" />
              </div>
              <Card side="mine" team={myTeam} monster={mine} />
            </div>
          )}
        </div>
      ) : (
        <div className="pkm-field"><p className="pkm-none">Pas encore d'adversaire.</p></div>
      )}

      {/* La boîte de commandes. Elle s'adresse à L'ÉQUIPE, pas au monstre : ici on ne dirige
          pas une créature, on décide à plusieurs — le monstre, lui, ne fait qu'encaisser.
          Le « vous » est aussi ce qui rappelle qu'on n'attaque jamais seul. */}
      <div className="pkm-menu">
        <div className="pkm-ask">
          <span>Que faites-vous ?</span>
          <b className="pkm-purse">🍑 {balls}<i>/{walletCap}</i></b>
        </div>

        <div className="pkm-cmds">
          <Cmd className="atk" icon="⚡" label="ATTAQUER" disabled={balls < attackCost || !foe}
               hint={`${attackCost} 🍑 · échec 1/${Math.round(1 / critFail)}`}
               onClick={() => act('attack')} />
          <Cmd className="heal" icon="💙" label="SOIGNER" disabled={balls < healCost || !mine}
               hint={`${healCost} 🍑 · +${healAmt} PV`}
               onClick={() => act('heal')} />
          <Cmd className="item" icon="🎒" label="POWER-UPS" disabled={usable === 0}
               hint={usable ? `${usable} objet${usable > 1 ? 's' : ''} prêt${usable > 1 ? 's' : ''}` : 'sac vide'}
               onClick={() => setPicking(true)} />
          <Cmd className="back" icon="🏡" label="RETOUR" hint="vers le hub" href="/" />
        </div>
      </div>

      {picking && (
        <ItemPicker items={items} onPick={onItem} onClose={() => setPicking(false)} />
      )}
      {trapItem && (
        <TargetPicker opponents={opponents} onPick={pickTarget} onClose={() => setTrapItem(null)} />
      )}
      {smokeItem && (
        <MonsterPicker myMonster={myTeam?.monster?.name} foeMonster={foeTeam?.monster?.name}
                       foeTeam={foeTeam?.name} onPick={pickMask} onClose={() => setSmokeItem(null)} />
      )}
      <BottomNav />
    </div>
  )
}

// La plaque d'identité d'un camp — le pendant de la barre de PV de Pokémon. Même contenu des
// deux côtés : qui c'est, ses PV, ses effets. Ce qui change, c'est le CHIP (ENNEMI / NOUS) et
// la couleur de la jauge, parce qu'un même chiffre ne veut pas dire la même chose selon le camp.
function Card({ side, team, monster }) {
  const foe = side === 'foe'
  const fill = foe ? 'crit' : hpClass(monster.percent)

  return (
    <div className={`pkm-card ${side}`}>
      <div className="pkm-who">
        <span className="n">{familyEmoji(team?.fruit_family)} {monster.name}{monster.protected ? ' 🥣' : ''}</span>
        <span className={`pkm-tag ${side}`}>{foe ? 'ENNEMI' : 'NOUS'}</span>
      </div>

      <div className="pkm-hp">
        <span className="lb">PV</span>
        <span className="bigbar">
          {monster.masked
            ? <i className="unknown" style={{ width: '100%' }} />
            : <i className={fill} style={{ width: `${monster.percent}%` }} />}
        </span>
      </div>

      <div className="pkm-foot">
        <EffectBadges effects={team?.effects} compact />
        <span className="pkm-num">
          {monster.masked ? '??? 🍦' : `${monster.hp.toLocaleString('fr-FR')} / ${monster.max_hp.toLocaleString('fr-FR')}`}
        </span>
      </div>
    </div>
  )
}

// Un bouton de commande, ou un lien quand il ne fait que sortir de l'écran (RETOUR).
function Cmd({ className, icon, label, hint, onClick, disabled, href }) {
  const inner = (
    <>
      <span className="t"><span className="i">{icon}</span>{label}</span>
      <span className="h">{hint}</span>
    </>
  )
  if (href) return <Link href={href} className={`pkm-cmd ${className}`}>{inner}</Link>

  return (
    <button type="button" className={`pkm-cmd ${className}`} onClick={onClick} disabled={disabled}>
      {inner}
    </button>
  )
}

// La jauge de NOTRE monstre change de couleur en descendant — vert, orange, rouge : c'est la
// convention de tous les jeux à barre de vie, et elle prévient avant que le chiffre soit lu.
// Celle de l'adversaire reste rouge quoi qu'il arrive : c'est une cible, pas une santé.
function hpClass(percent) {
  if (percent > 50) return 'good'
  if (percent > 20) return 'warn'
  return 'crit'
}
