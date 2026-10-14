import { csrf } from './csrf'

function urlBase64ToUint8Array(base64String) {
  const padding = '='.repeat((4 - (base64String.length % 4)) % 4)
  const base64 = (base64String + padding).replace(/-/g, '+').replace(/_/g, '/')
  const raw = atob(base64)
  return Uint8Array.from([...raw].map((c) => c.charCodeAt(0)))
}

export async function enablePush(vapidPublicKey) {
  if (!('serviceWorker' in navigator) || !('PushManager' in window)) {
    return { ok: false, message: "Ton navigateur ne supporte pas les notifications push." }
  }
  if (!vapidPublicKey) {
    return { ok: false, message: "Le push n'est pas encore configuré côté serveur (clés VAPID)." }
  }
  const permission = await Notification.requestPermission()
  if (permission !== 'granted') return { ok: false, message: "Autorisation refusée." }

  const reg = await navigator.serviceWorker.register('/service-worker')
  await navigator.serviceWorker.ready
  const sub = await reg.pushManager.subscribe({
    userVisibleOnly: true,
    applicationServerKey: urlBase64ToUint8Array(vapidPublicKey),
  })
  const json = sub.toJSON()
  const res = await fetch('/push_subscriptions', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': csrf() },
    body: JSON.stringify({ endpoint: json.endpoint, keys: json.keys }),
  })
  return res.ok
    ? { ok: true, message: "Notifications activées 🔔" }
    : { ok: false, message: "Échec de l'enregistrement de l'abonnement." }
}
