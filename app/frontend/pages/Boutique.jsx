import { Head, Link, router, usePage } from '@inertiajs/react'
import { useState } from 'react'
import BottomNav from '../components/BottomNav'
import TargetPicker from '../components/TargetPicker'
import MonsterPicker from '../components/MonsterPicker'
import { CosmeticIcon } from '../components/cosmeticArt'

const csrf = () =>
  (typeof document !== 'undefined' && document.querySelector('meta[name=csrf-token]')?.content) || ''

const itemEmoji = (t) =>
  ({ shield: '🥣', trap: '🐺', back_wind: '🌬️', face_wind: '🌪️', smoke: '🍦', wooden_leg: '🦿' }[t] || '🎒')
const rarityLabel = { common: 'Commun', rare: 'Rare', epic: 'Épique', legendary: 'Légendaire' }

export default function Boutique({ has_team, initial_tab, balls, items, cosmetics, seasonal, inventory, armed, opponents, team_names }) {
  const { auth, flash } = usePage().props
  const diamonds = auth.user?.diamonds ?? 0
  const [tab, setTab] = useState(initial_tab || 'items')
  const [trapItem, setTrapItem] = useState(null)   // objet piège en attente d'une cible
  const [smokeItem, setSmokeItem] = useState(null) // chantilly en attente du monstre à barbouiller

  const post = (url, data) => router.post(url, { ...data, authenticity_token: csrf() }, { preserveScroll: true })
  const buyItem = (id) => post('/boutique/items', { item_id: id })
  const buyCosmetic = (id) => post('/boutique/cosmetics', { cosmetic_id: id })
  const useItem = (it) => {
    if (it.effect_type === 'trap') return setTrapItem(it)
    if (it.effect_type === 'smoke') return setSmokeItem(it)
    post('/boutique/use', { item_id: it.item_id })
  }
  const trapTarget = (targetId) => { post('/boutique/use', { item_id: trapItem.item_id, target_id: targetId }); setTrapItem(null) }
  const smokeMask = (which) => { post('/boutique/use', { item_id: smokeItem.item_id, target_team: which }); setSmokeItem(null) }

  return (
    <div className="shell">
      <Head title="Boutique" />
      <div className="subhead">
        <Link href="/" className="back">←</Link>
        <div className="ti">🛒 Boutique</div>
        <span className="shop-wallet">
          <span className="curr">🍑 {balls}</span>
          <span className="curr">💎 {diamonds}</span>
        </span>
      </div>

      {flash?.notice && <div className="flash ok" style={{ margin: '10px 14px 0' }}>{flash.notice}</div>}
      {flash?.alert && <div className="flash err" style={{ margin: '10px 14px 0' }}>{flash.alert}</div>}

      <div className="chat-tabs">
        <button className={`chat-tab ${tab === 'items' ? 'on' : ''}`} onClick={() => setTab('items')}>🍑 Objets</button>
        <button className={`chat-tab ${tab === 'cosmetics' ? 'on' : ''}`} onClick={() => setTab('cosmetics')}>💎 Cosmétiques</button>
        <button className={`chat-tab ${tab === 'inventory' ? 'on' : ''}`} onClick={() => setTab('inventory')}>🎒 Sac</button>
      </div>

      <main className="body">
        {tab === 'items' && <Items items={items} balls={balls} hasTeam={has_team} onBuy={buyItem} />}
        {tab === 'cosmetics' && <Cosmetics cosmetics={cosmetics} seasonal={seasonal} diamonds={diamonds} onBuy={buyCosmetic} />}
        {tab === 'inventory' && <Inventory inventory={inventory} armed={armed} onUse={useItem} />}
      </main>

      {trapItem && (
        <TargetPicker opponents={opponents} onPick={trapTarget} onClose={() => setTrapItem(null)} />
      )}
      {smokeItem && (
        <MonsterPicker myMonster={team_names?.mine_monster} foeMonster={team_names?.foe_monster}
                       foeTeam={team_names?.foe} onPick={smokeMask} onClose={() => setSmokeItem(null)} />
      )}

      <BottomNav active="shop" />
    </div>
  )
}

function Items({ items, balls, hasTeam, onBuy }) {
  if (!hasTeam) {
    return <p className="shop-empty">Rejoins une partie pour acheter des objets : ils s'achètent en 🍑 boules, gagnées en courant.</p>
  }
  return (
    <div className="shop-list">
      {items.map((it) => (
        <div key={it.id} className="shop-card">
          <span className="shop-emoji">{itemEmoji(it.effect_type)}</span>
          <div className="shop-info">
            <div className="shop-name">{it.name}{it.owned > 0 && <span className="shop-own">×{it.owned}</span>}</div>
            <div className="shop-desc">{it.description}</div>
          </div>
          <button className="shop-buy" disabled={balls < it.price} onClick={() => onBuy(it.id)}>
            {it.price} 🍑
          </button>
        </div>
      ))}
    </div>
  )
}

// Le compte à rebours d'une pièce de saison. 0 = dernier jour, on le dit franchement.
const daysLabel = (n) => (n === 0 ? 'Dernier jour !' : n === 1 ? 'Encore 1 jour' : `Encore ${n} jours`)

function Cosmetics({ cosmetics, seasonal = [], diamonds, onBuy }) {
  return (
    <>
      {seasonal.length > 0 && (
        <section className="shop-season">
          <div className="shop-season-head">
            <span className="t">✨ Boutique de saison</span>
            <span className="s">Ces pièces repartent bientôt — après, il faudra attendre l'an prochain.</span>
          </div>
          <CosmeticGrid list={seasonal} diamonds={diamonds} onBuy={onBuy} season />
        </section>
      )}
      <CosmeticGrid list={cosmetics} diamonds={diamonds} onBuy={onBuy} />
    </>
  )
}

function CosmeticGrid({ list, diamonds, onBuy, season = false }) {
  return (
    <div className="shop-grid">
      {list.map((c) => (
        <div key={c.id} className={`shop-cos ${c.rarity} ${season ? 'season' : ''}`}>
          {season && c.days_left != null && <span className="shop-cos-left">⏳ {daysLabel(c.days_left)}</span>}
          <CosmeticIcon art={c.art} emoji={c.emoji} className="shop-cos-emoji" />
          <div className="shop-cos-name">{c.name}</div>
          <div className="shop-cos-rarity">{rarityLabel[c.rarity] || c.rarity}</div>
          {c.owned ? (
            <Link href="/avatar" className="shop-owned">{c.equipped ? '✓ Équipé' : 'Dans l\'armoire'}</Link>
          ) : (
            <button className="shop-buy full" disabled={diamonds < c.price} onClick={() => onBuy(c.id)}>
              {c.price} 💎
            </button>
          )}
        </div>
      ))}
    </div>
  )
}

function Inventory({ inventory, armed = [], onUse }) {
  return (
    <>
      {armed.length > 0 && (
        <>
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
        </>
      )}
      <h2 className="shop-h2">Objets à utiliser</h2>
      {inventory.length === 0 ? (
        <p className="shop-empty">Ton sac est vide. Achète des objets dans l'onglet 🍑.</p>
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
      <div className="shop-armoire">
        🎨 Tes cosmétiques se gèrent dans l'armoire.
        <Link href="/avatar">Ouvrir mon avatar →</Link>
      </div>
    </>
  )
}
