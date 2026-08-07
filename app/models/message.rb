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

  scope :chronological, -> { order(created_at: :asc) }

  # Ce qu'on met dans une notification ou un aperçu : le texte, sinon le meme.
  def preview(limit = 90)
    return body.truncate(limit) if body.present?

    "🖼️ #{meme_title.presence || 'un meme'}"
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
