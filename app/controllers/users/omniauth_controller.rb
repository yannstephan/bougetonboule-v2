class Users::OmniauthController < ApplicationController
  def google
    data = request.env["omniauth.auth"]
    user = User.find_by(google_uid: data.uid) ||
           User.find_by(email: data.info.email) ||
           User.new

    first_signup = user.new_record?

    if user.new_record?
      user.assign_attributes(
        email:      data.info.email,
        firstname:  data.info.first_name.presence || data.info.name,
        provider:   "google",
        avatar_url: data.info.image
      )
      user.save!
      Avatar.create!(user:)
    elsif user.google_uid.blank?
      user.update!(google_uid: data.uid, provider: "google")
    end

    sign_in(user)
    if first_signup
      redirect_to avatar_path, notice: "Bienvenue #{user.firstname} ! Choisis ton allure."
    else
      redirect_to root_path, notice: "Connecté avec Google !"
    end
  end

  def failure
    redirect_to login_path, alert: "Connexion Google échouée."
  end
end
