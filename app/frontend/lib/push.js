import { csrf } from './csrf'

function urlBase64ToUint8Array(base64String) {
  const padding = '='.repeat((4 - (base64String.length % 4)) % 4)
  const base64 = (base64String + padding).replace(/-/g, '+').replace(/_/g, '/')
  const raw = atob(base64)
  return Uint8Array.from([...raw].map((c) => c.charCodeAt(0)))
}

// L'abonnement push est un état du NAVIGATEUR, pas du compte : le serveur connaît des
// endpoints, mais il ne peut pas savoir si CELUI de cet appareil en fait partie. C'est donc
// au navigateur qu'on demande où on en est — sinon la page ne peut que proposer « Activer »
// à chaque visite, y compris à quelqu'un déjà abonné depuis des semaines.
//   'unsupported' · 'unconfigured' (pas de clés VAPID) · 'denied' (refus navigateur, un bouton
//   n'y peut plus rien) · 'on' (abonné sur cet appareil) · 'off' (reste à proposer).
export async function pushState(vapidPublicKey) {
  if (!('serviceWorker' in navigator) || !('PushManager' in window)) return 'unsupported'
  if (!vapidPublicKey) return 'unconfigured'
  if (Notification.permission === 'denied') return 'denied'
  if (Notification.permission !== 'granted') return 'off'

  // Permission accordée ne veut pas dire abonné : l'abonnement peut avoir été révoqué par le
  // navigateur (nettoyage, péremption de la clé) alors que l'autorisation, elle, reste.
  const reg = await navigator.serviceWorker.getRegistration()
  const sub = await reg?.pushManager?.getSubscription()
  if (!sub) return 'off'

  // Abonné ici, mais le serveur l'ignore peut-être (base restaurée, ligne élaguée) : on
  // repousse l'endpoint en silence. `find_or_initialize_by(endpoint)` le dédoublonne, donc
  // c'est gratuit quand il est déjà connu — et c'est ce qui évite de redemander un geste au
  // joueur pour un abonnement que son navigateur a toujours.
  await saveSubscription(sub)
  return 'on'
}

async function saveSubscription(sub) {
  const json = sub.toJSON()
  return fetch('/push_subscriptions', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', 'X-CSRF-Token': csrf() },
    body: JSON.stringify({ endpoint: json.endpoint, keys: json.keys }),
  })
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
  const res = await saveSubscription(sub)
  return res.ok
    ? { ok: true, message: "Notifications activées 🔔" }
    : { ok: false, message: "Échec de l'enregistrement de l'abonnement." }
}
