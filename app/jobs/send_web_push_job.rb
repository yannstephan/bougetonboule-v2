# Envoie une notification en Web Push (VAPID) à tous les appareils abonnés d'un user.
class SendWebPushJob < ApplicationJob
  queue_as :default

  def perform(notification_id)
    notif = Notification.find_by(id: notification_id)
    return unless notif

    vapid = Rails.application.config.x.vapid
    return if vapid[:public_key].blank? || vapid[:private_key].blank?

    payload = { title: notif.title.presence || "Bouge Ton Boule",
                body: notif.body.to_s, url: "/notifications" }.to_json

    notif.user.push_subscriptions.find_each do |sub|
      WebPush.payload_send(
        message: payload, endpoint: sub.endpoint, p256dh: sub.p256dh_key, auth: sub.auth_key,
        vapid: { subject: vapid[:subject], public_key: vapid[:public_key], private_key: vapid[:private_key] }
      )
    rescue WebPush::ExpiredSubscription, WebPush::InvalidSubscription
      sub.destroy
    rescue StandardError => e
      Rails.logger.error("[WebPush] #{e.class}: #{e.message}")
    end
  end
end
