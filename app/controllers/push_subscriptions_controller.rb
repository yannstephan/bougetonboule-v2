class PushSubscriptionsController < ApplicationController
  before_action :require_authentication

  def create
    sub = current_user.push_subscriptions.find_or_initialize_by(endpoint: params[:endpoint])
    sub.update!(
      p256dh_key: params.dig(:keys, :p256dh),
      auth_key:   params.dig(:keys, :auth),
      user_agent: request.user_agent,
      last_used_at: Time.current
    )
    head :ok
  end
end
