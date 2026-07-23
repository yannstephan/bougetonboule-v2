module Authentication
  extend ActiveSupport::Concern

  included do
    helper_method :current_user, :user_signed_in?
  end

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
  end

  def user_signed_in? = current_user.present?

  def sign_in(user)
    reset_session
    session[:user_id] = user.id
    @current_user = user
  end

  def sign_out
    reset_session
    @current_user = nil
  end

  def require_authentication
    redirect_to login_path, alert: "Connecte-toi pour continuer." unless user_signed_in?
  end
end
