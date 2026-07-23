class NotificationsController < ApplicationController
  before_action :require_authentication

  def index
    render inertia: "Notifications", props: {
      notifications: current_user.notifications.recent.limit(50).map do |n|
        { id: n.id, category: n.category, title: n.title, body: n.body,
          read: n.read?, at: n.created_at.strftime("%d/%m %H:%M") }
      end
    }
  end

  def read_all
    current_user.notifications.unread.update_all(read_at: Time.current)
    redirect_to notifications_path
  end
end
