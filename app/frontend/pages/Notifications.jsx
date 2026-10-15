import { Head, Link, usePage } from '@inertiajs/react'
import { useEffect, useState } from 'react'
import { enablePush, pushState } from '../lib/push'
import Hud from '../components/Hud'
import BottomNav from '../components/BottomNav'

const icon = (c) => ({
  attacked: '⚡', healed: '💚', streak: '🔥', chest: '🎁', message: '💬',
  special_day: '🎄', training_verified: '✅', game_start: '🎮', league: '🏅', trap: '🐺', effect: '✨',
}[c] || '🔔')

export default function Notifications({ notifications }) {
  const { vapid_public_key } = usePage().props
  const [pushMsg, setPushMsg] = useState(null)
  // null = on ne sait pas encore. On ne montre RIEN tant que le navigateur n'a pas répondu :
  // afficher « Activer » par défaut le ferait clignoter à chaque visite chez un abonné.
  const [push, setPush] = useState(null)

  useEffect(() => {
    let alive = true
    pushState(vapid_public_key).then((st) => alive && setPush(st)).catch(() => alive && setPush('off'))
    return () => { alive = false }
  }, [vapid_public_key])

  const activate = async () => {
    setPushMsg('…')
    const r = await enablePush(vapid_public_key)
    setPushMsg(r.message)
    if (r.ok) setPush('on')
  }

  const important = notifications.filter((n) => n.importance === 'important')
  const secondary = notifications.filter((n) => n.importance !== 'important')

  return (
    <div className="shell">
      <Head title="Notifications" />
      <Hud />

      <main className="body">
        {/* Déjà abonné sur cet appareil : une ligne qui le confirme, pas un bouton. Et rien
            du tout si le push n'est pas supporté ou pas configuré — proposer d'activer ce
            qui ne peut pas l'être n'aide personne. */}
        {push === 'off' && (
          <div className="push-cta">
            <span>🔔 Reçois une alerte pour ce qui te concerne (messages d'équipe, pièges…).</span>
            <button onClick={activate}>Activer</button>
          </div>
        )}
        {push === 'on' && (
          <div className="push-cta on">🔔 Notifications activées sur cet appareil.</div>
        )}
        {push === 'denied' && (
          <div className="push-cta">
            <span>🔕 Les notifications sont bloquées pour ce site. Ça se rouvre dans les
              réglages du navigateur (cadenas de la barre d'adresse → Notifications).</span>
          </div>
        )}
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
      <BottomNav />
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
