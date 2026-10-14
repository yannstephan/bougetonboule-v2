# Catalogue de la boutique : les cosmétiques et les objets (power-ups).
#
# ⚠️ Ce sont des **données de référence**, pas de la démonstration. Sans elles la boutique est
# vide, les coffres n'ont aucun cosmétique à tirer et les paliers de série rien à offrir. Elles
# vivent donc ici et NON dans db/seeds.rb, dont la garde de production bloque tout le fichier.
#
# **Idempotent** : chaque pièce est retrouvée PAR SON NOM et ses attributs remis à jour.
# Relancer ne duplique rien, et corriger un prix ici suffit à le corriger en production au
# prochain chargement.
#
#   bin/rails catalog:load
#
# Le seed de démonstration l'appelle aussi : une seule source de vérité pour le catalogue.
class LoadCatalog
  Result = Struct.new(:created, :updated, :items_created, :items_updated, keyword_init: true)

  def self.call(...) = new(...).call

  # `demo_summer` : la collection d'été est calée sur AUJOURD'HUI pour que le seed de démo
  # montre le rayon de saison. En production elle prend ses vraies dates de calendrier.
  def initialize(demo_summer: false)
    @demo_summer = demo_summer
  end

  def call
    result = Result.new(created: 0, updated: 0, items_created: 0, items_updated: 0)

    ActiveRecord::Base.transaction do
      guard_unique_names!

      cosmetics.each do |attrs|
        piece = Cosmetic.find_or_initialize_by(name: attrs[:name])
        piece.new_record? ? result.created += 1 : result.updated += 1
        # Les fenêtres de saison absentes doivent REDEVENIR nil : une pièce rendue permanente
        # dans ce fichier ne doit pas garder son ancienne date en base.
        piece.update!({ available_from: nil, available_until: nil }.merge(attrs))
      end

      items.each do |attrs|
        item = Item.find_or_initialize_by(name: attrs[:name])
        item.new_record? ? result.items_created += 1 : result.items_updated += 1
        item.update!(attrs)
      end
    end

    result
  end

  private

  # Le nom est la clé : un doublon dans ce fichier créerait silencieusement deux pièces
  # (il n'y a pas d'index unique en base). On refuse plutôt que de polluer le catalogue.
  def guard_unique_names!
    [ [ cosmetics, "cosmétique" ], [ items, "objet" ] ].each do |list, label|
      doublons = list.map { |a| a[:name] }.tally.select { |_, n| n > 1 }.keys
      raise "Nom de #{label} en double dans LoadCatalog : #{doublons.join(', ')}" if doublons.any?
    end
  end

  # ——— Boutique de saison ———
  # Une pièce peut n'exister qu'un temps : `available_from` / `available_until` (l'une ou
  # l'autre, ou les deux). Hors fenêtre elle disparaît de la boutique ET des tirages (coffre,
  # streak, ligue) — mais ce qui est déjà acheté reste acquis pour toujours.
  # ⚠️ Ces dates s'ajustent depuis /admin sans redéployer : ce ne sont que des valeurs de départ.
  def ete
    return [ 12.days.ago, 16.days.from_now ] if @demo_summer

    [ Time.zone.local(2027, 6, 21), Time.zone.local(2027, 9, 21, 23, 59) ]
  end

  def halloween = [ Time.zone.local(2026, 10, 15), Time.zone.local(2026, 11, 5, 23, 59) ]
  def noel      = [ Time.zone.local(2026, 12, 1), Time.zone.local(2027, 1, 6, 23, 59) ]

  # L'avatar est une TÊTE de fruit : 7 emplacements, ni tenue ni jambes (voir Cosmetic::SLOTS).
  # Prix calés sur la streak hebdo (~1 100 💎 max sur une saison parfaite, voir GameRules) :
  # common ~100 · rare ~250 · epic ~500 · legendary 1000.
  #
  # `emoji` par défaut ; `art` quand l'emoji ne peut pas faire le travail — les chaussures
  # (👟 🥾 🛼 sont des godasses uniques vues de profil, on veut une PAIRE de face) et les
  # pièces dont l'emoji est un visage entier (🤠 🧐 🎅 auraient collé une tête sur la tête).
  # Chaque clé `art` doit exister dans components/cosmeticArt.jsx.
  # ——— Boutique de saison ———
  # Une pièce peut n'exister qu'un temps : `available_from` / `available_until` (l'une ou
  # l'autre, ou les deux). Hors fenêtre elle disparaît de la boutique ET des tirages (coffre,
  # streak, ligue) — mais ce qui est déjà acheté reste à toi pour toujours.
  # La collection d'été est calée sur AUJOURD'HUI pour que la démo montre le rayon ; les deux
  # autres ont les vraies dates de l'année.
  def cosmetics
    ete, halloween, noel = self.ete, self.halloween, self.noel

    [
    # Chapeaux — posés sur le sommet réel du fruit (voir fruits.js → box)
    { name: "Bandeau éponge",     slot: "hat",  rarity: "common",    price_diamonds: 90,   source: "shop",  emoji: "🎀" },
    { name: "Casquette",          slot: "hat",  rarity: "common",    price_diamonds: 100,  source: "shop",  emoji: "🧢" },
    { name: "Capeline d'été",     slot: "hat",  rarity: "common",    price_diamonds: 100,  source: "shop",  emoji: "👒" },
    { name: "Bob du dimanche",    slot: "hat",  rarity: "rare",      price_diamonds: 240,  source: "shop",  art: "bucket_hat" },
    { name: "Chapeau de cowboy",  slot: "hat",  rarity: "rare",      price_diamonds: 250,  source: "shop",  art: "cowboy_hat" },
    { name: "Toque de diplômé",   slot: "hat",  rarity: "epic",      price_diamonds: 500,  source: "shop",  emoji: "🎓" },
    { name: "Casque de chantier", slot: "hat",  rarity: "epic",      price_diamonds: 500,  source: "shop",  emoji: "⛑️" },
    { name: "Haut-de-forme doré", slot: "hat",  rarity: "legendary", price_diamonds: 1000, source: "shop",  art: "gold_hat" },
    # Lunettes — sur la ligne des yeux, commune à tous les fruits
    { name: "Lunettes rondes",    slot: "eyes", rarity: "common",    price_diamonds: 90,   source: "shop",  emoji: "👓" },
    { name: "Lunettes de piscine", slot: "eyes", rarity: "common",   price_diamonds: 100,  source: "shop",  emoji: "🥽" },
    { name: "Masque de plongée",  slot: "eyes", rarity: "common",    price_diamonds: 110,  source: "shop",  emoji: "🤿" },
    { name: "Lunettes de star",   slot: "eyes", rarity: "rare",      price_diamonds: 250,  source: "shop",  emoji: "🕶️" },
    { name: "Cache-œil de pirate", slot: "eyes", rarity: "rare",     price_diamonds: 260,  source: "shop",  art: "eyepatch" },
    { name: "Visière du futur",   slot: "eyes", rarity: "epic",      price_diamonds: 550,  source: "shop",  art: "visor" },
    { name: "Monocle du mentor",  slot: "eyes", rarity: "legendary", price_diamonds: 1000, source: "shop",  art: "monocle" },
    # Cou — juste au-dessus de la base du fruit
    { name: "Cravate du dimanche", slot: "neck", rarity: "common",   price_diamonds: 90,   source: "shop",  emoji: "👔" },
    { name: "Écharpe de laine",   slot: "neck", rarity: "common",    price_diamonds: 100,  source: "shop",  emoji: "🧣" },
    { name: "Nœud papillon",      slot: "neck", rarity: "common",    price_diamonds: 100,  source: "shop",  art: "bowtie" },
    { name: "Dossard de course",  slot: "neck", rarity: "common",    price_diamonds: 110,  source: "shop",  art: "bib" },
    { name: "Collier de perles",  slot: "neck", rarity: "rare",      price_diamonds: 250,  source: "shop",  emoji: "📿" },
    { name: "Bandana",            slot: "neck", rarity: "rare",      price_diamonds: 240,  source: "shop",  art: "bandana" },
    { name: "Chaîne en or",       slot: "neck", rarity: "epic",      price_diamonds: 500,  source: "shop",  emoji: "🪙" },
    # Bras — un de chaque côté, à la largeur du fruit (le droit en miroir).
    # La pièce doit représenter UN bras : 🧤 et 🐾 sont des paires, ils sont dessinés.
    { name: "Gants d'hiver",      slot: "hands", rarity: "common",   price_diamonds: 90,   source: "shop",  art: "mitten" },
    { name: "Montre GPS",         slot: "hands", rarity: "rare",     price_diamonds: 250,  source: "shop",  emoji: "⌚" },
    { name: "Gants de boxe",      slot: "hands", rarity: "rare",     price_diamonds: 260,  source: "shop",  emoji: "🥊" },
    { name: "Bras mécanique",     slot: "hands", rarity: "epic",     price_diamonds: 520,  source: "shop",  emoji: "🦾" },
    { name: "Patte de loup",      slot: "hands", rarity: "epic",     price_diamonds: 550,  source: "shop",  art: "paw" },
    { name: "Baguette magique",   slot: "hands", rarity: "legendary", price_diamonds: 1000, source: "shop", art: "wand" },
    # Chaussures — une PAIRE vue de face sous le fruit
    { name: "Tongs",              slot: "shoes", rarity: "common",   price_diamonds: 90,   source: "shop",  emoji: "🩴" },
    { name: "Baskets de course",  slot: "shoes", rarity: "common",   price_diamonds: 110,  source: "shop",  art: "sneakers" },
    { name: "Chaussures de rando", slot: "shoes", rarity: "rare",    price_diamonds: 240,  source: "shop",  art: "trail" },
    { name: "Ballerines",         slot: "shoes", rarity: "rare",     price_diamonds: 250,  source: "shop",  art: "ballet" },
    { name: "Patins à glace",     slot: "shoes", rarity: "rare",     price_diamonds: 250,  source: "shop",  emoji: "⛸️" },
    { name: "Rollers dorés",      slot: "shoes", rarity: "epic",     price_diamonds: 500,  source: "shop",  art: "skates" },
    { name: "Bottes de sept lieues", slot: "shoes", rarity: "legendary", price_diamonds: 1000, source: "shop", art: "boots7" },
    # Accessoire — posé à côté du fruit
    { name: "Gourde",             slot: "sidekick", rarity: "common", price_diamonds: 90,  source: "shop",  emoji: "🥤" },
    { name: "Crotte porte-bonheur", slot: "sidekick", rarity: "common", price_diamonds: 90, source: "shop", emoji: "💩" },
    { name: "Barre protéinée",    slot: "sidekick", rarity: "common", price_diamonds: 100, source: "shop",  emoji: "🍫" },
    { name: "Banane de course",   slot: "sidekick", rarity: "common", price_diamonds: 110, source: "shop",  emoji: "🎒" },
    { name: "Maracas",            slot: "sidekick", rarity: "common", price_diamonds: 110, source: "shop",  art: "maracas" },
    { name: "Chien de course",    slot: "sidekick", rarity: "rare",  price_diamonds: 250,  source: "shop",  emoji: "🐕" },
    { name: "Chat supporter",     slot: "sidekick", rarity: "rare",  price_diamonds: 250,  source: "shop",  emoji: "🐈" },
    { name: "Paresseux",          slot: "sidekick", rarity: "rare",  price_diamonds: 250,  source: "shop",  emoji: "🦥" },
    { name: "Perroquet exotique", slot: "sidekick", rarity: "epic",  price_diamonds: 500,  source: "shop",  emoji: "🦜" },
    { name: "Chrono du coach",    slot: "sidekick", rarity: "epic",  price_diamonds: 520,  source: "shop",  emoji: "⏱️" },
    { name: "Sac de butin",       slot: "sidekick", rarity: "epic",  price_diamonds: 520,  source: "shop",  emoji: "💰" },
    { name: "Guépard",            slot: "sidekick", rarity: "epic",  price_diamonds: 550,  source: "shop",  emoji: "🐆" },
    # Auras — une couronne de 6 petits emojis, derrière le fruit
    { name: "Pétales de cerisier", slot: "aura", rarity: "common",   price_diamonds: 110,  source: "shop",  emoji: "🌸" },
    { name: "Aura pêche",         slot: "aura", rarity: "common",    price_diamonds: 120,  source: "shop",  emoji: "✨" },
    { name: "Double cœur",        slot: "aura", rarity: "common",    price_diamonds: 120,  source: "shop",  emoji: "💕" },
    { name: "Trèfle à quatre feuilles", slot: "aura", rarity: "rare", price_diamonds: 250, source: "shop",  emoji: "🍀" },
    { name: "Aura de givre",      slot: "aura", rarity: "rare",      price_diamonds: 250,  source: "shop",  emoji: "❄️" },
    { name: "Aura de feu",        slot: "aura", rarity: "epic",      price_diamonds: 550,  source: "shop",  emoji: "🔥" },
    { name: "Aura électrique",    slot: "aura", rarity: "epic",      price_diamonds: 550,  source: "shop",  emoji: "⚡" },
    { name: "Arc-en-ciel",        slot: "aura", rarity: "legendary", price_diamonds: 1000, source: "shop",  emoji: "🌈" },
    # Exclusives — jamais en vente (price nil) : tirages (streak, ligue), coffres, jours spéciaux
    { name: "Couronne de Noël",   slot: "hat",  rarity: "legendary", price_diamonds: nil,  source: "event", emoji: "👑",
      available_from: noel[0], available_until: noel[1] },
    { name: "Bonnet du Réveillon", slot: "hat", rarity: "epic",      price_diamonds: nil,  source: "event", art: "santa_hat",
      available_from: noel[0], available_until: noel[1] },
    { name: "Citrouille maudite", slot: "hat",  rarity: "epic",      price_diamonds: nil,  source: "event", emoji: "🎃",
      available_from: halloween[0], available_until: halloween[1] },
    { name: "Fantôme d'Halloween", slot: "sidekick", rarity: "epic", price_diamonds: nil,  source: "event", emoji: "👻",
      available_from: halloween[0], available_until: halloween[1] },
    { name: "Médaille d'Odyssea", slot: "neck", rarity: "legendary", price_diamonds: nil,  source: "rank",  emoji: "🏅" },
    { name: "Esprit du loup",     slot: "aura", rarity: "legendary", price_diamonds: nil,  source: "drop",  emoji: "🐺" },
    { name: "Ailes de dossard",   slot: "aura", rarity: "epic",      price_diamonds: nil,  source: "drop",  emoji: "🦋" },
    # Boutique de saison — en vente, mais seulement pendant leur fenêtre
    { name: "Parasol",            slot: "sidekick", rarity: "common", price_diamonds: 110, source: "shop", emoji: "⛱️",
      available_from: ete[0], available_until: ete[1] },
    { name: "Tournesol",          slot: "aura", rarity: "common",    price_diamonds: 120,  source: "shop", emoji: "🌻",
      available_from: ete[0], available_until: ete[1] },
    { name: "Bouée canard",       slot: "sidekick", rarity: "rare",  price_diamonds: 250,  source: "shop", emoji: "🦆",
      available_from: ete[0], available_until: ete[1] },
    { name: "Araignée porte-poisse", slot: "sidekick", rarity: "rare", price_diamonds: 250, source: "shop", emoji: "🕷️",
      available_from: halloween[0], available_until: halloween[1] },
    { name: "Toile de sorcière",  slot: "aura", rarity: "rare",      price_diamonds: 250,  source: "shop", emoji: "🕸️",
      available_from: halloween[0], available_until: halloween[1] },
    { name: "Sapin scintillant",  slot: "aura", rarity: "rare",      price_diamonds: 250,  source: "shop", emoji: "🎄",
      available_from: noel[0], available_until: noel[1] },
    { name: "Renne du traîneau",  slot: "sidekick", rarity: "rare",  price_diamonds: 260,  source: "shop", emoji: "🦌",
      available_from: noel[0], available_until: noel[1] }
    ]
  end

  # Prix calibrés sur les données de la saison v1 (~10 🍑/semaine pour un actif médian).
  # Le booster n'est plus un objet : c'est la jauge de meute (PackLevelJob), gagnée en courant.
  def items
    [
    { name: "Jambe de bois", price: 4, description: "Déjoue le prochain piège sur ta course",             effect_type: "wooden_leg" },
    { name: "Vent de dos",   price: 4, description: "×1,5 sur les boules de l'équipe pendant 12h",        effect_type: "back_wind" },
    { name: "Vent de face",  price: 4, description: "−25 % sur les boules adverses pendant 12h",          effect_type: "face_wind" },
    { name: "Chantilly",     price: 4, description: "Chantilly plein les yeux : masque les PV d'un monstre à l'équipe adverse (24h)", effect_type: "smoke" },
    { name: "Piège à loup",  price: 5, description: "Annule les boules de la prochaine course d'un adversaire", effect_type: "trap" },
    { name: "Saladier",      price: 6, description: "Saladier retourné sur ton monstre : intouchable pendant 6h", effect_type: "shield" }
    ]
  end
end
