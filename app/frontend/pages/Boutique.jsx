import { Head, Link, router, usePage } from '@inertiajs/react'
import { useState } from 'react'
import BottomNav from '../components/BottomNav'

const csrf = () =>
  (typeof document !== 'undefined' && document.querySelector('meta[name=csrf-token]')?.content) || ''

const itemEmoji = (t) => ({ shield: '🛡️', trap: '🐺', back_wind: '🌬️', booster: '✖️' }[t] || '🎒')
const rarityLabel = { common: 'Commun', rare: 'Rare', epic: 'Épique', legendary: 'Légendaire' }

export default function Boutique({ has_team, balls, items, cosmetics, inventory }) {
  const { auth, flash } = usePage().props
  const diamonds = auth.user?.diamonds ?? 0
  const [tab, setTab] = useState('items')

  const post = (url, data) => router.post(url, { ...data, authenticity_token: csrf() }, { preserveScroll: true })
  const buyItem = (id) => post('/boutique/items', { item_id: id })
  const buyCosmetic = (id) => post('/boutique/cosmetics', { cosmetic_id: id })
  const useItem = (id) => post('/boutique/use', { item_id: id })

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
        {tab === 'cosmetics' && <Cosmetics cosmetics={cosmetics} diamonds={diamonds} onBuy={buyCosmetic} />}
        {tab === 'inventory' && <Inventory inventory={inventory} onUse={useItem} />}
      </main>

      <BottomNav active="shop" />
    </div>
  )
}

function Items({ items, balls, hasTeam, onBuy }) {
  if (!hasTeam) {
    return <p className="shop-empty">Rejoins une partie pour acheter des objets : ils s'achètent en 🍑 pêches, gagnées en courant.</p>
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
              <button className="shop-use" onClick={() => onUse(it.item_id)}>Utiliser</button>
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
