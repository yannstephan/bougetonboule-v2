class User < ApplicationRecord
  has_secure_password validations: false

  has_many :memberships, dependent: :destroy
  has_many :games, through: :memberships
  has_many :user_cosmetics, dependent: :destroy
  has_many :cosmetics, through: :user_cosmetics
  has_many :push_subscriptions, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :rewards, dependent: :destroy

  # Chiffrés au repos : un jeton d'actualisation Strava donne accès aux activités du joueur
  # jusqu'à révocation. Chiffrement NON déterministe (le plus robuste), possible parce
  # qu'aucun code ne cherche un utilisateur PAR son jeton — seul `strava_uid` sert aux
  # recherches, et lui reste en clair (c'est un identifiant, pas un secret).
  # Clés et garde-fous : voir config/application.rb.
  encrypts :strava_token
  encrypts :strava_refresh_token

  validates :email, presence: true, uniqueness: { case_sensitive: false }
  # Un compte Strava = un joueur : on ne branche pas le compte d'un ami qui court plus.
  validates :strava_uid, uniqueness: true, allow_nil: true
  validates :password, length: { minimum: 6 }, allow_nil: true

  def strava_connected? = strava_uid.present?
end
