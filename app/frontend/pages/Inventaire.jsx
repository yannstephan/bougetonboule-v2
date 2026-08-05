import { Head, Link, router, usePage } from '@inertiajs/react'
import { useState } from 'react'
import BottomNav from '../components/BottomNav'
import TargetPicker from '../components/TargetPicker'
import MonsterPicker from '../components/MonsterPicker'
import Wardrobe from '../components/Wardrobe'
import ChestCard, { ChestReveal } from '../components/ChestCard'
import Hud from '../components/Hud'

const csrf = () =>
  (typeof document !== 'undefined' && document.querySelector('meta[name=csrf-token]')?.content) || ''

const itemEmoji = (t) =>
  ({ shield: '🥣', trap: '🐺', back_wind: '🌬️', face_wind: '🌪️', smoke: '🍦', wooden_leg: '🦿' }[t] || '🎒')

// Le sac tient les deux inventaires du joueur : les objets de la partie (🍑, à usage unique)
// et l'armoire des cosmétiques (💎, globale). C'est le seul endroit d'où l'on ouvre un coffre
// et d'où l'on équipe une pièce.
export default function Inventaire({ has_team, initial_tab, balls, chests, inventory, armed,
                                     opponents, team_names, avatar, cosmetics, slots }) {
  const { auth, flash } = usePage().props
  const diamonds = auth.user?.diamonds ?? 0
  const [tab, setTab] = useState(initial_tab || 'items')
  const [trapItem, setTrapItem] = useState(null)   // objet piège en attente d'une cible
  const [smokeItem, setSmokeItem] = useState(null) // chantilly en attente du monstre à barbouiller

  const post = (url, data) => router.post(url, { ...data, authenticity_token: csrf() }, { preserveScroll: true })
  const useItem = (it) => {
    if (it.effect_type === 'trap') return setTrapItem(it)
    if (it.effect_type === 'smoke') return setSmokeItem(it)
    post('/sac/utiliser', { item_id: it.item_id })
  }
  const trapTarget = (targetId) => { post('/sac/utiliser', { item_id: trapItem.item_id, target_id: targetId }); setTrapItem(null) }
  const smokeMask = (which) => { post('/sac/utiliser', { item_id: smokeItem.item_id, target_team: which }); setSmokeItem(null) }
  const toggleCosmetic = (c) => post('/sac/equiper', { cosmetic_id: c.id, equipped: !c.equipped })

  return (
    <div className="shell">
      <Head title="Mon sac" />
      <Hud />

      <div className="subhead">
        <Link href="/" className="back">←</Link>
        <div className="ti">🎒 Mon sac</div>
      </div>

      {has_team && (
        <div className="chat-tabs">
          <button className={`chat-tab ${tab === 'items' ? 'on' : ''}`} onClick={() => setTab('items')}>
            🎒 Objets{chests.length > 0 && <span className="tab-dot" />}
          </button>
          <button className={`chat-tab ${tab === 'wardrobe' ? 'on' : ''}`} onClick={() => setTab('wardrobe')}>🎨 Armoire</button>
        </div>
      )}

      {flash?.notice && <div className="flash ok" style={{ margin: '10px 14px 0' }}>{flash.notice}</div>}
      {flash?.alert && <div className="flash err" style={{ margin: '10px 14px 0' }}>{flash.alert}</div>}

      <main className="body">
        {!has_team ? (
          <p className="shop-empty">Rejoins une partie pour avoir un sac : les objets s'achètent en 🍑 boules, gagnées en courant.</p>
        ) : tab === 'wardrobe' ? (
          <Wardrobe avatar={avatar} cosmetics={cosmetics} slots={slots} onToggle={toggleCosmetic} />
        ) : (
          <Items chests={chests} armed={armed} inventory={inventory} onUse={useItem} />
        )}
      </main>

      <ChestReveal />
      {trapItem && (
        <TargetPicker opponents={opponents} onPick={trapTarget} onClose={() => setTrapItem(null)} />
      )}
      {smokeItem && (
        <MonsterPicker myMonster={team_names?.mine_monster} foeMonster={team_names?.foe_monster}
                       foeTeam={team_names?.foe} onPick={smokeMask} onClose={() => setSmokeItem(null)} />
      )}

      <BottomNav active="bag" />
    </div>
  )
}

function Items({ chests, armed, inventory, onUse }) {
  return (
    <>
      {chests.length > 0 && (
        <section className="bag-sec">
          <h2 className="shop-h2">🎁 À ouvrir</h2>
          {chests.map((c) => <ChestCard key={c.id} chest={c} />)}
        </section>
      )}

      {armed.length > 0 && (
        <section className="bag-sec">
          <h2 className="shop-h2">En préparation</h2>
          <div className="shop-list">
            {armed.map((a, i) => (
              <div key={i} className="shop-card armed">
                <span className="shop-emoji">{itemEmoji(a.effect_type)}</span>
                <div className="shop-info">
                  <div className="shop-name">
                    {a.effect_type === 'wooden_leg' ? 'Jambe de bois' : 'Piège à loup'}
                  </div>
                  <div className="shop-desc">
                    {a.effect_type === 'wooden_leg'
                      ? 'Armée — elle déjouera un piège sur ta prochaine course.'
                      : `Posé sur ${a.target || '?'} — se referme à sa prochaine course.`}
                    {a.placed_at ? ` · ${a.placed_at}` : ''}
                  </div>
                </div>
              </div>
            ))}
          </div>
        </section>
      )}

      <section className="bag-sec">
        <h2 className="shop-h2">Objets à utiliser</h2>
        {inventory.length === 0 ? (
          <p className="shop-empty">Ton sac est vide. Achète des objets à la boutique 🛒.</p>
        ) : (
          <div className="shop-list">
            {inventory.map((it) => (
              <div key={it.item_id} className="shop-card">
                <span className="shop-emoji">{itemEmoji(it.effect_type)}</span>
                <div className="shop-info">
                  <div className="shop-name">{it.name}<span className="shop-own">×{it.count}</span></div>
                  <div className="shop-desc">{it.active ? 'Déjà en cours — attends qu\'il se termine.' : it.description}</div>
                </div>
                <button className="shop-use" onClick={() => onUse(it)} disabled={it.active}>
                  {it.active ? 'En cours' : 'Utiliser'}
                </button>
              </div>
            ))}
          </div>
        )}
      </section>
    </>
  )
}
