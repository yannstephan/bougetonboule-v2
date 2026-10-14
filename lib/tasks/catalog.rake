namespace :catalog do
  desc "Charge ou actualise le catalogue de la boutique (cosmétiques + objets) — idempotent"
  task load: :environment do
    r = LoadCatalog.call
    puts "✅ Cosmétiques : #{r.created} créé(s), #{r.updated} actualisé(s) — #{Cosmetic.count} en tout"
    puts "✅ Objets      : #{r.items_created} créé(s), #{r.items_updated} actualisé(s) — #{Item.count} en tout"
  end
end
