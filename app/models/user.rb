class User < ApplicationRecord
  has_secure_password validations: false

  has_many :memberships, dependent: :destroy
  has_many :games, through: :memberships
  has_many :user_cosmetics, dependent: :destroy
  has_many :cosmetics, through: :user_cosmetics
  has_many :push_subscriptions, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :rewards, dependent: :destroy

  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :password, length: { minimum: 6 }, allow_nil: true

  def strava_connected? = strava_uid.present?
end
