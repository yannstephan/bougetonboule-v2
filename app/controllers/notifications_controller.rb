class NotificationsController < ApplicationController
  before_action :require_authentication

  def index
    # On sérialise avec l'état actuel (les non-lues restent surlignées pour CETTE visite)…
    notifications = current_user.notifications.recent.limit(50).map do |n|
      { id: n.id, category: n.category, importance: n.importance, title: n.title, body: n.body,
        link: n.link, read: n.read?, at: n.created_at.strftime("%d/%m %H:%M") }
    end
    # …puis on marque tout comme lu dès l'ouverture (la pastille 🔔 retombe à 0).
    current_user.notifications.unread.update_all(read_at: Time.current)

    render inertia: "Notifications", props: { notifications: notifications }
  end
end
