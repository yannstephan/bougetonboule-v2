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

self.addEventListener("notificationclick", (event) => {
  event.notification.close()
  event.waitUntil(clients.openWindow(event.notification.data.url || "/"))
})
