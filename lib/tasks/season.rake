# Réglages temporels de la saison, en ligne de commande — même chose que l'écran /admin,
# pour le jour où on est en SSH sur le serveur plutôt que sur son téléphone.
namespace :season do
  desc "Affiche journées spéciales et fenêtres de la boutique de saison"
  task show: :environment do
    Game.where(status: "active").find_each do |game|
      puts "\n#{game.name}"
      puts "  🎉 Journées spéciales"
      days = game.special_days.order(:date)
      puts("     (aucune)") if days.empty?
      days.each do |d|
        puts format("     %s  ×%d  %-22s%s", d.date.strftime("%d/%m/%Y"), d.multiplier, d.name,
                    d.date < Date.current ? " (passée)" : "")
      end
    end

    puts "\n✨ Boutique de saison (pièces datées)"
    dated = Cosmetic.seasonal.order(:available_from, :name)
    puts("   (aucune)") if dated.empty?
    dated.each do |c|
      window = [ c.available_from&.to_date&.strftime("%d/%m/%Y") || "…",
                c.available_until&.to_date&.strftime("%d/%m/%Y") || "…" ].join(" → ")
      puts format("   %-28s %-24s %s", c.name, window, c.available? ? "EN COURS" : "fermée")
    end

    puts "
🏷️  Panoplies"
    sets = CosmeticSet.includes(:cosmetics).ordered
    puts("   (aucune)") if sets.empty?
    sets.each do |set|
      pieces = set.cosmetics.select(&:price_diamonds)
      promo = if set.promo_percent
        window = [ set.promo_from&.to_date&.strftime("%d/%m/%Y") || "…",
                  set.promo_until&.to_date&.strftime("%d/%m/%Y") || "…" ].join(" → ")
        "-#{set.promo_percent}% #{window} #{set.promo? ? '(EN COURS)' : '(inactive)'}"
      else
        "pas de promo"
      end
      puts format("   %-24s %d pièces  %4d 💎 → %4d 💎   %s", set.name, pieces.size,
                  pieces.sum(&:price_diamonds), pieces.sum { |c| c.current_price.to_i }, promo)
    end
  end

  desc "Ajoute une journée ×2 (NAME='Halloween' DATE=2026-10-31 [MULT=2] [GAME_ID=1])"
  task special_day: :environment do
    name = ENV.fetch("NAME") { abort "NAME= manquant" }
    date = Date.parse(ENV.fetch("DATE") { abort "DATE= manquant (AAAA-MM-JJ)" })
    games = ENV["GAME_ID"] ? Game.where(id: ENV["GAME_ID"]) : Game.where(status: "active")

    games.each do |game|
      day = game.special_days.create!(name:, date:, multiplier: (ENV["MULT"] || 2).to_i)
      puts "#{game.name} — ×#{day.multiplier} le #{day.date.strftime('%d/%m/%Y')} : #{day.name}"
    end
  end

  desc "Ouvre une collection (NAMES='Parasol,Tournesol' [FROM=2026-10-15] [UNTIL=2026-11-05])"
  task open: :environment do
    names = ENV.fetch("NAMES") { abort "NAMES='Nom 1,Nom 2' manquant" }.split(",").map(&:strip)
    from  = ENV["FROM"].presence && Date.parse(ENV["FROM"]).beginning_of_day
    till  = ENV["UNTIL"].presence && Date.parse(ENV["UNTIL"]).end_of_day
    abort "FROM doit précéder UNTIL" if from && till && from > till

    names.each do |name|
      cosmetic = Cosmetic.find_by(name:)
      next puts("⚠️  inconnu : #{name}") if cosmetic.nil?

      cosmetic.update!(available_from: from, available_until: till)
      puts "#{name} → #{cosmetic.seasonal? ? "#{from&.to_date || '…'} → #{till&.to_date || '…'}" : 'permanent'}"
    end
  end

  desc "Lance une promo (SET='Coureur du dimanche' PERCENT=20 [FROM=2026-11-01] [UNTIL=2026-11-15])"
  task promo: :environment do
    set = CosmeticSet.find_by(name: ENV.fetch("SET") { abort "SET='Nom de la panoplie' manquant" })
    abort "Panoplie inconnue" if set.nil?

    set.promo_percent = ENV.fetch("PERCENT") { abort "PERCENT= manquant (1 à 90)" }.to_i
    set.promo_from    = ENV["FROM"].presence && Date.parse(ENV["FROM"]).beginning_of_day
    set.promo_until   = ENV["UNTIL"].presence && Date.parse(ENV["UNTIL"]).end_of_day
    abort set.errors.full_messages.to_sentence unless set.save

    puts "#{set.name} → -#{set.promo_percent}% (#{set.promo? ? 'en cours' : 'programmée'})"
    set.cosmetics.each { |c| puts format("   %-28s %4d 💎 → %4d 💎", c.name, c.price_diamonds, c.current_price) }
  end

  desc "Arrête la promo d'une panoplie (SET='Coureur du dimanche')"
  task unpromo: :environment do
    set = CosmeticSet.find_by(name: ENV.fetch("SET") { abort "SET= manquant" })
    abort "Panoplie inconnue" if set.nil?

    # On n'écrit rien dans les prix : les retirer suffit à rétablir le catalogue.
    set.update!(promo_percent: nil, promo_from: nil, promo_until: nil)
    puts "#{set.name} → prix d'origine rétablis"
  end

  desc "Rend des pièces permanentes (NAMES='Parasol,Tournesol')"
  task close: :environment do
    ENV.fetch("NAMES") { abort "NAMES='Nom 1,Nom 2' manquant" }.split(",").map(&:strip).each do |name|
      cosmetic = Cosmetic.find_by(name:)
      next puts("⚠️  inconnu : #{name}") if cosmetic.nil?

      cosmetic.update!(available_from: nil, available_until: nil)
      puts "#{name} → permanent"
    end
  end
end
