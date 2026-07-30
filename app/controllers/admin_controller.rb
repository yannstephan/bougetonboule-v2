# Back-office minimal, réservé à l'admin de la partie en cours (`Membership#admin?`).
#
# Il ne couvre QUE les deux réglages qui se pilotent par des dates et qu'on veut pouvoir
# changer sans déployer :
#   - les journées spéciales (×2 sur les boules) ;
#   - la fenêtre de disponibilité des cosmétiques (la boutique de saison).
# Le reste du contenu (créer une partie, des équipes) reste au seed — voir la roadmap.
class AdminController < ApplicationController
  before_action :require_authentication
  before_action :require_admin

  def show
    render inertia: "Admin", props: {
      game: { id: @game.id, name: @game.name,
              starts_at: @game.starts_at&.iso8601, ends_at: @game.ends_at&.iso8601 },
      today: Date.current.iso8601,
      special_days: special_days_json,
      cosmetics: cosmetics_json
    }
  end

  def create_special_day
    day = @game.special_days.new(special_day_params)
    if day.save
      redirect_to admin_path, notice: "Journée spéciale « #{day.name} » ajoutée."
    else
      redirect_to admin_path, alert: day.errors.full_messages.to_sentence
    end
  end

  def destroy_special_day
    day = @game.special_days.find(params[:id])
    day.destroy
    redirect_to admin_path, notice: "« #{day.name} » supprimée."
  end

  # Pose (ou retire) la fenêtre de disponibilité d'un cosmétique. Un champ vide = pas de
  # borne de ce côté ; les deux vides = la pièce redevient permanente.
  def update_cosmetic
    cosmetic = Cosmetic.find(params[:id])
    from  = parse_day(params[:available_from])
    until_ = parse_day(params[:available_until], end_of_day: true)

    if from && until_ && from > until_
      return redirect_to admin_path, alert: "La date de fin doit venir après la date de début."
    end

    cosmetic.update!(available_from: from, available_until: until_)
    redirect_to admin_path, notice: "#{cosmetic.name} : #{window_label(cosmetic)}"
  end

  private

  def require_admin
    @membership = current_membership
    return redirect_to root_path, alert: "Réservé à l'organisateur de la partie." unless @membership&.admin?

    @game = @membership.game
  end

  def special_day_params = params.permit(:name, :date, :multiplier)

  # Les dates arrivent en "YYYY-MM-DD" (input type=date) : on les lit dans le fuseau du jeu,
  # et une date de FIN vaut jusqu'au bout de sa journée (sinon elle expire à minuit pile).
  def parse_day(value, end_of_day: false)
    return nil if value.blank?

    day = Date.parse(value)
    end_of_day ? day.end_of_day : day.beginning_of_day
  rescue Date::Error
    nil
  end

  def window_label(cosmetic)
    return "disponible en permanence" unless cosmetic.seasonal?

    from = cosmetic.available_from&.to_date&.strftime("%d/%m/%Y")
    till = cosmetic.available_until&.to_date&.strftime("%d/%m/%Y")
    return "disponible jusqu'au #{till}" if from.nil?
    return "disponible à partir du #{from}" if till.nil?

    "disponible du #{from} au #{till}"
  end

  def special_days_json
    @game.special_days.order(:date).map do |d|
      { id: d.id, name: d.name, date: d.date.iso8601, multiplier: d.multiplier.to_f,
        past: d.date < Date.current }
    end
  end

  def cosmetics_json
    Cosmetic.order(:slot, :name).map do |c|
      { id: c.id, name: c.name, slot: c.slot, emoji: c.emoji, art: c.art,
        price: c.price_diamonds, rarity: c.rarity,
        available_from: c.available_from&.to_date&.iso8601,
        available_until: c.available_until&.to_date&.iso8601,
        live: c.available? }
    end
  end
end
