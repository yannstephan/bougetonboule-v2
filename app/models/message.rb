class Message < ApplicationRecord
  belongs_to :conversation
  belongs_to :membership
  has_one :user, through: :membership

  # Un message porte du texte, un meme, ou les deux — mais pas rien.
  validate :some_content
  # Ceinture et bretelles avec le contrôleur : même par la console, `meme_url` ne peut
  # contenir qu'une URL du fournisseur de memes. Ce n'est pas un champ d'image libre.
  validates :meme_url, format: { with: /\Ahttps:\/\//, message: "doit être une URL https" },
                       allow_blank: true
  validate :meme_from_provider

  # ⚠️ L'`id` départage : le seed pose des `created_at` à la main, deux messages peuvent donc
  # partager la seconde. Sans ce second critère, l'ordre serait indéterminé — et la pagination
  # du chat, qui remonte le fil avec un curseur (created_at, id), sauterait ou répéterait des
  # messages à la frontière d'une page.
  scope :chronological, -> { order(:created_at, :id) }

  # Ce qu'on met dans une notification ou un aperçu : le texte, sinon le meme.
  def preview(limit = 90)
    return body.truncate(limit) if body.present?

    "🖼️ #{meme_title.presence || 'un GIF'}"
  end

  private

  def some_content
    return if body.present? || meme_url.present?

    errors.add(:base, "Un message ne peut pas être vide.")
  end

  def meme_from_provider
    return if meme_url.blank? || Memes.allowed?(meme_url)

    errors.add(:meme_url, "ne vient pas du catalogue de memes.")
  end
end
