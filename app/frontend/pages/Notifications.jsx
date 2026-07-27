import { Head, Link, router, usePage } from '@inertiajs/react'
import { useState } from 'react'
import { enablePush } from '../lib/push'

const csrf = () =>
  (typeof document !== 'undefined' && document.querySelector('meta[name=csrf-token]')?.content) || ''

const icon = (c) => ({
  attacked: '⚡', healed: '💚', streak: '🔥', chest: '🎁', message: '💬',
  special_day: '🎄', training_verified: '✅', game_start: '🎮', league: '🏅', trap: '🐺', effect: '✨',
}[c] || '🔔')

export default function Notifications({ notifications }) {
  const { vapid_public_key } = usePage().props
  const [pushMsg, setPushMsg] = useState(null)

  const activate = async () => {
    setPushMsg('…')
    const r = await enablePush(vapid_public_key)
    setPushMsg(r.message)
  }

  const readAll = () =>
    router.post('/notifications/read_all', { authenticity_token: csrf() }, { preserveScroll: true })

  const important = notifications.filter((n) => n.importance === 'important')
  const secondary = notifications.filter((n) => n.importance !== 'important')

  return (
    <div className="shell">
      <Head title="Notifications" />
      <div className="subhead">
        <Link href="/" className="back">←</Link>
        <div className="ti">🔔 Notifications</div>
        <button className="chat-tab" style={{ marginLeft: 'auto', flex: 'none' }} onClick={readAll}>Tout lire</button>
      </div>

      <main className="body">
        <div className="push-cta">
          <span>🔔 Reçois une alerte pour ce qui te concerne (messages d'équipe, pièges…).</span>
          <button onClick={activate}>Activer</button>
        </div>
        {pushMsg && <div className="flash ok">{pushMsg}</div>}

        {notifications.length === 0 && (
          <div className="chat-empty" style={{ marginTop: 30 }}>Aucune notification pour l'instant.</div>
        )}

        {important.length > 0 && (
          <section className="notif-sec">
            <h2 className="notif-h">Pour toi</h2>
            {important.map((n) => <Notif key={n.id} n={n} />)}
          </section>
        )}

        {secondary.length > 0 && (
          <section className="notif-sec">
            <h2 className="notif-h">Activité de la partie</h2>
            {secondary.map((n) => <Notif key={n.id} n={n} secondary />)}
          </section>
        )}
      </main>
    </div>
  )
}

function Notif({ n, secondary = false }) {
  return (
    <div className={`notif ${n.read ? '' : 'unread'} ${secondary ? 'sec' : ''}`}>
      <div className="nic">{icon(n.category)}</div>
      <div className="nt">
        <div className="nti">{n.title}</div>
        <div className="nb">{n.body}</div>
        <div className="nh">{n.at}</div>
      </div>
      {!n.read && !secondary && <div className="udot" />}
    </div>
  )
}
