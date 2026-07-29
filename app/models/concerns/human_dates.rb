# Dates telles qu'un joueur les lit. Un seul endroit pour les libellés en français —
# la même journée doit s'écrire pareil dans le chat, sur une sortie et dans le classement.
module HumanDates
  MONTHS = %w[janvier février mars avril mai juin
              juillet août septembre octobre novembre décembre].freeze

  module_function

  # "Aujourd'hui" · "Hier" · "12/03/2027"
  def day_label(time)
    case time.to_date
    when Date.current   then "Aujourd'hui"
    when Date.yesterday then "Hier"
    else time.strftime("%d/%m/%Y")
    end
  end

  # "juillet 2026" au fil d'une phrase, "Juillet 2026" en titre de classement.
  def month_name(date) = "#{MONTHS[date.month - 1]} #{date.year}"
  def month_label(date) = month_name(date).capitalize
end
