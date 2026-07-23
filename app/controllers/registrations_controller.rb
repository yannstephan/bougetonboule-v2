class RegistrationsController < ApplicationController
  def new
    redirect_to root_path and return if user_signed_in?
    render inertia: "auth/Register"
  end

  def create
    user = User.new(
      firstname: params[:firstname].to_s.strip,
      email:     params[:email].to_s.downcase.strip,
      password:  params[:password]
    )
    if params[:password].blank?
      redirect_to register_path, alert: "Choisis un mot de passe." and return
    end
    if user.save
      Avatar.create!(user:)
      sign_in(user)
      redirect_to root_path, notice: "Bienvenue sur Bouge Ton Boule, #{user.firstname} !"
    else
      redirect_to register_path, alert: user.errors.full_messages.to_sentence
    end
  end
end
