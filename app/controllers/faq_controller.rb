class FaqController < ApplicationController
  before_action :require_authentication

  # Règles du jeu — page statique, le contenu vit côté React (pages/Faq.jsx).
  def show
    render inertia: "Faq"
  end
end
