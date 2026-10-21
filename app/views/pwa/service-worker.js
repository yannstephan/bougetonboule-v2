// Service worker de la PWA — servi par /service-worker (Rails::PwaController rend
// le template "pwa/service-worker", AVEC tiret : ne pas renommer ce fichier).
// Il reçoit les Web Push (VAPID) et ouvre l'app au clic sur la notification.

self.addEventListener("push", (event) => {
  let data = {}
  try { data = event.data.json() } catch (e) { data = { body: event.data && event.data.text() } }
  const title = data.title || "Bouge Ton Boule"
  event.waitUntil(
    self.registration.showNotification(title, {
      body: data.body || "",
      icon: "/icon.png",
      badge: "/icon.png",
      data: { url: data.url || "/" },
    })
  )
})

// Si l'app est déjà ouverte, on la ramène au premier plan sur la bonne page plutôt que d'en
// ouvrir une deuxième fenêtre (sur Android, la PWA se dédoublait à chaque notification).
self.addEventListener("notificationclick", (event) => {
  event.notification.close()
  const url = new URL(event.notification.data.url || "/", self.location.origin).href
  event.waitUntil((async () => {
    const open = await clients.matchAll({ type: "window", includeUncontrolled: true })
    const client = open.find((c) => new URL(c.url).origin === self.location.origin)
    if (client && "navigate" in client) {
      await client.focus()
      return client.navigate(url)
    }
    return clients.openWindow(url)
  })())
})
