class SessionsController < ApplicationController
  def new
    redirect_to root_path and return if user_signed_in?
    render inertia: "auth/Login"
  end

  def create
    user = User.find_by(email: params[:email].to_s.downcase.strip)
    if user&.authenticate(params[:password])
      sign_in(user)
      redirect_to root_path, notice: "Content de te revoir, #{user.firstname} !"
    else
      redirect_to login_path, alert: "Email ou mot de passe incorrect."
    end
  end

  def destroy
    sign_out
    redirect_to login_path, notice: "À bientôt !"
  end
end
