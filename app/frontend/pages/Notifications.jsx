import { Head, Link, usePage } from '@inertiajs/react'
import { useState } from 'react'
import { enablePush } from '../lib/push'
import SubHeader from '../components/SubHeader'

// Une icône par catégorie de notification (Notification::CATEGORIES côté back).
const icon = (c) => ({
  attacked: '⚡', healed: '💚', crit_failed: '💥', effect: '✨', trap: '🐺',
  chest: '🎁', streak: '🔥', league: '🏅', training_verified: '✅', message: '💬',
  pack: '🐾', famine: '🍽️', game_over: '🏁',
}[c] || '🔔')

export default function Notifications({ notifications }) {
  const { vapid_public_key } = usePage().props
  const [pushMsg, setPushMsg] = useState(null)

  const activate = async () => {
    setPushMsg('…')
    const r = await enablePush(vapid_public_key)
    setPushMsg(r.message)
  }

  const important = notifications.filter((n) => n.importance === 'important')
  const secondary = notifications.filter((n) => n.importance !== 'important')

  return (
    <div className="shell">
      <Head title="Notifications" />
      <SubHeader title="🔔 Notifications" />

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
  const cls = `notif ${n.read ? '' : 'unread'} ${secondary ? 'sec' : ''} ${n.link ? 'clickable' : ''}`
  const inner = (
    <>
      <div className="nic">{icon(n.category)}</div>
      <div className="nt">
        <div className="nti">{n.title}</div>
        <div className="nb">{n.body}</div>
        <div className="nh">{n.at}</div>
      </div>
      {n.link ? <span className="nchev">›</span> : !n.read && !secondary && <div className="udot" />}
    </>
  )
  return n.link
    ? <Link href={n.link} className={cls}>{inner}</Link>
    : <div className={cls}>{inner}</div>
}
