import { Head, Link, router, usePage } from '@inertiajs/react'
import { useState } from 'react'
import BottomNav from '../components/BottomNav'
import TargetPicker from '../components/TargetPicker'
import TeamPicker from '../components/TeamPicker'
import SubHeader from '../components/SubHeader'
import Flash from '../components/Flash'
import { csrf } from '../lib/csrf'
import { itemEmoji, rarityLabel } from '../lib/labels'

export default function Boutique({ has_team, balls, items, cosmetics, inventory, opponents, team_names }) {
  const { auth } = usePage().props
  const diamonds = auth.user?.diamonds ?? 0
  const [tab, setTab] = useState('items')
  const [trapItem, setTrapItem] = useState(null)   // objet piège en attente d'une cible
  const [smokeItem, setSmokeItem] = useState(null) // fumigène en attente d'une équipe

  const post = (url, data) => router.post(url, { ...data, authenticity_token: csrf() }, { preserveScroll: true })
  const buyItem = (id) => post('/boutique/items', { item_id: id })
  const buyCosmetic = (id) => post('/boutique/cosmetics', { cosmetic_id: id })
  const useItem = (it) => {
    if (it.effect_type === 'trap') return setTrapItem(it)
    if (it.effect_type === 'smoke') return setSmokeItem(it)
    post('/boutique/use', { item_id: it.item_id })
  }
  const trapTarget = (targetId) => { post('/boutique/use', { item_id: trapItem.item_id, target_id: targetId }); setTrapItem(null) }
  const smokeTeam = (which) => { post('/boutique/use', { item_id: smokeItem.item_id, target_team: which }); setSmokeItem(null) }

  return (
    <div className="shell">
      <Head title="Boutique" />
      <SubHeader title="🛒 Boutique">
        <span className="shop-wallet">
          <span className="curr">🍑 {balls}</span>
          <span className="curr">💎 {diamonds}</span>
        </span>
      </SubHeader>

      <Flash inset />

      <div className="chat-tabs">
        <button className={`chat-tab ${tab === 'items' ? 'on' : ''}`} onClick={() => setTab('items')}>🍑 Objets</button>
        <button className={`chat-tab ${tab === 'cosmetics' ? 'on' : ''}`} onClick={() => setTab('cosmetics')}>💎 Cosmétiques</button>
        <button className={`chat-tab ${tab === 'inventory' ? 'on' : ''}`} onClick={() => setTab('inventory')}>🎒 Sac</button>
      </div>

      <main className="body">
        {tab === 'items' && <Items items={items} balls={balls} hasTeam={has_team} onBuy={buyItem} />}
        {tab === 'cosmetics' && <Cosmetics cosmetics={cosmetics} diamonds={diamonds} onBuy={buyCosmetic} />}
        {tab === 'inventory' && <Inventory inventory={inventory} onUse={useItem} />}
      </main>

      {trapItem && (
        <TargetPicker opponents={opponents} onPick={trapTarget} onClose={() => setTrapItem(null)} />
      )}
      {smokeItem && (
        <TeamPicker myTeam={team_names?.mine} foeTeam={team_names?.foe} onPick={smokeTeam} onClose={() => setSmokeItem(null)} />
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

function Cosmetics({ cosmetics, diamonds, onBuy }) {
  return (
    <div className="shop-grid">
      {cosmetics.map((c) => (
        <div key={c.id} className={`shop-cos ${c.rarity}`}>
          <span className="shop-cos-emoji">{c.emoji || '🎁'}</span>
          <div className="shop-cos-name">{c.name}</div>
          <div className="shop-cos-rarity">{rarityLabel(c.rarity)}</div>
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

function Inventory({ inventory, onUse }) {
  return (
    <>
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
                <div className="shop-desc">{it.description}</div>
              </div>
              <button className="shop-use" onClick={() => onUse(it)}>Utiliser</button>
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
