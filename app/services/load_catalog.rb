# Catalogue de la boutique : les cosmétiques (dont les panoplies) et les objets (power-ups).
#
# ⚠️ Ce sont des **données de référence**, pas de la démonstration. Sans elles la boutique est
# vide, les coffres n'ont aucun cosmétique à tirer et les paliers de série rien à offrir. Elles
# vivent donc ici et NON dans db/seeds.rb, dont la garde de production bloque tout le fichier.
#
# **Idempotent** : chaque pièce est retrouvée PAR SON NOM (les panoplies aussi) et ses attributs
# remis à jour. Relancer ne duplique rien, et corriger un prix ici suffit à le corriger en
# production au prochain chargement — sans migration ni reseed.
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

      # Les panoplies d'abord : les cosmétiques qui en font partie doivent trouver l'objet
      # CosmeticSet déjà en base (ou tout juste créé) pour s'y rattacher.
      set_records = load_sets

      cosmetics.each do |raw|
        attrs = raw.dup
        set_name = attrs.delete(:set)
        piece = Cosmetic.find_or_initialize_by(name: attrs[:name])
        piece.new_record? ? result.created += 1 : result.updated += 1
        # Les fenêtres de saison et la panoplie absentes doivent REDEVENIR nil : une pièce
        # rendue permanente, ou sortie d'une panoplie, dans ce fichier ne doit pas garder son
        # ancienne valeur en base.
        defaults = { available_from: nil, available_until: nil, cosmetic_set: nil }
        piece.update!(defaults.merge(attrs).merge(cosmetic_set: set_name && set_records.fetch(set_name)))
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

  def load_sets
    sets.to_h do |name, description|
      set = CosmeticSet.find_or_initialize_by(name:)
      set.update!(description:)
      [ name, set ]
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

  # Une PANOPLIE : un thème, plusieurs pièces, toutes de la MÊME rareté (validé par le modèle).
  # On achète toujours à la pièce — la panoplie range le rayon et porte les promotions, qui se
  # posent depuis /admin (pourcentage + dates) et ne touchent jamais au prix catalogue.
  def sets
    {
      "Coureur du dimanche" => "Celui qui court une fois par semaine, en coton, avec un café dans le ventre.",
      "Le plongeur" => "Palmes, masque et tuba. Il ne court pas vite, mais il ne s'essouffle jamais.",
      "Le loup" => "Celui qui court la nuit, seul, et rentre avant que la meute s'en aperçoive.",
      "Noël" => "Les bois sur la tête, la guirlande autour du cou, et un renne qui suit.",
      "Le Père Noël" => "La panoplie complète : le bonnet, la barbe, les bottes et les bras chargés.",
      "L'intello" => "Haut-de-forme, monocle, et un verre de rouge pour réfléchir en courant.",
      "Le chanceux" => "Il ne s'entraîne pas, il a de la chance. Ça marche presque aussi bien.",
      "La ballerine" => "Diadème, tutu et chaussons. Les bras en couronne, même en côte.",
      "Le fantôme" => "Un drap, deux trous. Personne ne saura que c'est toi qui marches dans les côtes.",
      "Le plagiste" => "Casquette à quartiers, short à rayures, pelle et seau. Le sable, c'est du dénivelé.",
    }
  end

  # L'avatar est une TÊTE de fruit : 7 emplacements, ni tenue ni jambes (voir Cosmetic::SLOTS).
  # Prix calés sur la streak hebdo (~1 100 💎 max sur une saison parfaite, voir GameRules) :
  # common ~100 · rare ~250 · epic ~500 · legendary 1000.
  #
  # `emoji` par défaut ; `art` quand l'emoji ne peut pas faire le travail — les chaussures
  # (👟 🥾 🛼 sont des godasses uniques vues de profil, on veut une PAIRE de face) et les
  # pièces dont l'emoji est un visage entier (🤠 🧐 🎅 auraient collé une tête sur la tête).
  # Chaque clé `art` doit exister dans components/cosmeticArt.jsx.
  #
  # Les auras ne s'achètent ni ne se tirent : chacune est la RÉCOMPENSE d'une panoplie, offerte
  # quand on en possède toutes les autres pièces (UnlockSetAura). D'où `price_diamonds: nil`
  # et `source: "set"` sur toutes, y compris celles qui n'ont pas encore de panoplie.
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
    # Lunettes — sur la ligne des yeux, commune à tous les fruits
    { name: "Lunettes rondes",    slot: "eyes", rarity: "common",    price_diamonds: 90,   source: "shop",  emoji: "👓" },
    { name: "Lunettes de piscine", slot: "eyes", rarity: "common",   price_diamonds: 100,  source: "shop",  emoji: "🥽" },
    { name: "Masque de plongée",  slot: "eyes", rarity: "common",    price_diamonds: 110,  source: "shop",  emoji: "🤿" },
    { name: "Lunettes de star",   slot: "eyes", rarity: "rare",      price_diamonds: 250,  source: "shop",  emoji: "🕶️" },
    { name: "Cache-œil de pirate", slot: "eyes", rarity: "rare",     price_diamonds: 260,  source: "shop",  art: "eyepatch" },
    { name: "Visière du futur",   slot: "eyes", rarity: "epic",      price_diamonds: 550,  source: "shop",  art: "visor" },
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
    { name: "Baguette magique",   slot: "hands", rarity: "legendary", price_diamonds: 1000, source: "shop", art: "wand" },
    # Chaussures — une PAIRE vue de face sous le fruit
    { name: "Tongs",              slot: "shoes", rarity: "common",   price_diamonds: 90,   source: "shop",  emoji: "🩴" },
    { name: "Baskets de course",  slot: "shoes", rarity: "common",   price_diamonds: 110,  source: "shop",  art: "sneakers" },
    { name: "Chaussures de rando", slot: "shoes", rarity: "rare",    price_diamonds: 240,  source: "shop",  art: "trail" },
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
    # Auras — le FOND DE PAGE du joueur (voir AuraBackground). Récompenses de panoplie, pas en vente.
    { name: "Pétales de cerisier", slot: "aura", rarity: "common",   price_diamonds: nil,  source: "set",  emoji: "🌸" },
    { name: "Aura pêche",         slot: "aura", rarity: "common",    price_diamonds: nil,  source: "set",  emoji: "✨" },
    { name: "Double cœur",        slot: "aura", rarity: "common",    price_diamonds: nil,  source: "set",  emoji: "💕" },
    { name: "Aura de feu",        slot: "aura", rarity: "epic",      price_diamonds: nil,  source: "set",  emoji: "🔥" },
    { name: "Aura électrique",    slot: "aura", rarity: "epic",      price_diamonds: nil,  source: "set",  emoji: "⚡" },
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
    { name: "Ailes de dossard",   slot: "aura", rarity: "epic",      price_diamonds: nil,  source: "set",  emoji: "🦋" },
    # Boutique de saison — en vente, mais seulement pendant leur fenêtre
    { name: "Parasol",            slot: "sidekick", rarity: "common", price_diamonds: 110, source: "shop", emoji: "⛱️",
      available_from: ete[0], available_until: ete[1] },
    { name: "Bouée canard",       slot: "sidekick", rarity: "rare",  price_diamonds: 250,  source: "shop", emoji: "🦆",
      available_from: ete[0], available_until: ete[1] },
    { name: "Tournesol",          slot: "aura", rarity: "common",    price_diamonds: nil,  source: "set", emoji: "🌻",
      available_from: ete[0], available_until: ete[1] },
    { name: "Araignée porte-poisse", slot: "sidekick", rarity: "rare", price_diamonds: 250, source: "shop", emoji: "🕷️",
      available_from: halloween[0], available_until: halloween[1] },

    # ——— Panoplies ———
    # Coureur du dimanche (commune, 100 💎) — trois pièces DESSINÉES : l'emoji ne pouvait pas
    # les porter. 🎧 est un casque vu de face qui faisait une masse noire sur le crâne, 📱 un
    # téléphone posé là plutôt qu'un brassard, et 🎽 un débardeur — une TENUE, alors que
    # l'avatar est une tête (d'où la serviette).
    { name: "Écouteurs du dimanche", slot: "hat",      rarity: "common", price_diamonds: 100, source: "shop",
      art: "headphones",        set: "Coureur du dimanche" },
    { name: "Serviette éponge",      slot: "neck",     rarity: "common", price_diamonds: 100, source: "shop",
      art: "towel",             set: "Coureur du dimanche" },
    { name: "Téléphone en brassard", slot: "hands",    rarity: "common", price_diamonds: 100, source: "shop",
      art: "armband",           set: "Coureur du dimanche" },
    { name: "Baskets fatiguées",     slot: "shoes",    rarity: "common", price_diamonds: 100, source: "shop",
      art: "worn_sneakers",     set: "Coureur du dimanche" },
    { name: "Café d'avant-course",   slot: "sidekick", rarity: "common", price_diamonds: 100, source: "shop",
      emoji: "☕",              set: "Coureur du dimanche" },
    { name: "Souffle court",         slot: "aura",     rarity: "common", price_diamonds: nil, source: "set",
      emoji: "💨",              set: "Coureur du dimanche" },

    # Le plongeur (rare, 250 💎) — objectif de collection pour qui a déjà tout le rayon commun.
    # Cinq pièces sur six sont dessinées — un plongeur, ça ne se raconte pas avec des emojis à plat.
    { name: "Bonnet de bain",    slot: "hat",      rarity: "rare", price_diamonds: 250, source: "shop",
      art: "swim_cap",     set: "Le plongeur" },
    { name: "Masque et tuba",    slot: "eyes",     rarity: "rare", price_diamonds: 250, source: "shop",
      art: "dive_mask",    set: "Le plongeur" },
    { name: "Ceinture de plomb", slot: "neck",     rarity: "rare", price_diamonds: 250, source: "shop",
      art: "weight_belt",  set: "Le plongeur" },
    { name: "Harpon et lampe",   slot: "hands",    rarity: "rare", price_diamonds: 250, source: "shop",
      art: "wetsuit_arms", set: "Le plongeur" },
    { name: "Palmes",            slot: "shoes",    rarity: "rare", price_diamonds: 250, source: "shop",
      art: "flippers",     set: "Le plongeur" },
    { name: "Banc de poissons",  slot: "aura",     rarity: "rare", price_diamonds: nil, source: "set",
      emoji: "🐠",         set: "Le plongeur" },

    # Le loup (épique, 500 💎) — donne enfin une maison à l'Esprit du loup, aura orpheline.
    # ⚠️ Son aura est LÉGENDAIRE alors que les pièces sont épiques : la règle « une panoplie,
    # une rareté » porte sur ce qu'on PAIE, et une aura ne se paie pas (voir Cosmetic).
    { name: "Oreilles de loup",  slot: "hat",      rarity: "epic", price_diamonds: 500, source: "shop",
      art: "wolf_ears",     set: "Le loup" },
    { name: "Balafre",           slot: "eyes",     rarity: "epic", price_diamonds: 500, source: "shop",
      art: "scar",          set: "Le loup" },
    { name: "Collier à pointes", slot: "neck",     rarity: "epic", price_diamonds: 500, source: "shop",
      art: "spiked_collar", set: "Le loup" },
    { name: "Patte de loup",     slot: "hands",    rarity: "epic", price_diamonds: 500, source: "shop",
      art: "paw",           set: "Le loup" },
    { name: "Coussinets",        slot: "shoes",    rarity: "epic", price_diamonds: 500, source: "shop",
      art: "wolf_paws",     set: "Le loup" },
    { name: "Os à ronger",       slot: "sidekick", rarity: "epic", price_diamonds: 500, source: "shop",
      emoji: "🦴",          set: "Le loup" },
    { name: "Esprit du loup",    slot: "aura",     rarity: "legendary", price_diamonds: nil, source: "set",
      emoji: "🐺",          set: "Le loup" },

    # Noël (rare, 250 💎) — SAISONNIÈRE : ses six pièces portent la fenêtre, donc le rayon
    # entier apparaît le 1er décembre et disparaît le 6 janvier.
    { name: "Bois de renne",       slot: "hat",      rarity: "rare", price_diamonds: 250, source: "shop",
      art: "antlers",      set: "Noël", available_from: noel[0], available_until: noel[1] },
    # ⚠️ Le bonnet de ces lunettes monte jusqu'au crâne : porté avec les Bois de renne (slot
    # chapeau de la même panoplie), il disparaît sous eux. Les deux pièces se choisissent.
    { name: "Lunettes du Père Noël", slot: "eyes",   rarity: "rare", price_diamonds: 250, source: "shop",
      art: "santa_glasses", set: "Noël", available_from: noel[0], available_until: noel[1] },
    { name: "Guirlande lumineuse", slot: "neck",     rarity: "rare", price_diamonds: 250, source: "shop",
      art: "garland",      set: "Noël", available_from: noel[0], available_until: noel[1] },
    { name: "Manteau et moufles",  slot: "hands",    rarity: "rare", price_diamonds: 250, source: "shop",
      art: "xmas_arms",    set: "Noël", available_from: noel[0], available_until: noel[1] },
    { name: "Bottes de Noël",      slot: "shoes",    rarity: "rare", price_diamonds: 250, source: "shop",
      art: "xmas_boots",   set: "Noël", available_from: noel[0], available_until: noel[1] },
    { name: "Renne du traîneau",   slot: "sidekick", rarity: "rare", price_diamonds: 250, source: "shop",
      emoji: "🦌",         set: "Noël", available_from: noel[0], available_until: noel[1] },
    { name: "Sapin scintillant",   slot: "aura",     rarity: "rare", price_diamonds: nil, source: "set",
      emoji: "🎄",         set: "Noël", available_from: noel[0], available_until: noel[1] },

    # Le Père Noël (rare, 250 💎) — PERMANENTE : un déguisement, pas une collection de saison.
    # ⚠️ La barbe occupe le slot des LUNETTES : impossible de porter les deux, exactement ce
    # qu'on veut d'une barbe de Père Noël.
    { name: "Bonnet du Père Noël",  slot: "hat",   rarity: "rare", price_diamonds: 250, source: "shop",
      art: "santa_hat",   set: "Le Père Noël" },
    { name: "Grande barbe blanche", slot: "eyes",  rarity: "rare", price_diamonds: 250, source: "shop",
      art: "beard",       set: "Le Père Noël" },
    { name: "Bras chargés de cadeaux", slot: "hands", rarity: "rare", price_diamonds: 250, source: "shop",
      art: "gift_arms",   set: "Le Père Noël" },
    { name: "Bottes à boucle",      slot: "shoes", rarity: "rare", price_diamonds: 250, source: "shop",
      art: "santa_boots", set: "Le Père Noël" },
    { name: "Aura de givre",        slot: "aura",  rarity: "rare", price_diamonds: nil, source: "set",
      emoji: "❄️",        set: "Le Père Noël" },

    # L'intello (légendaire, 1 000 💎) — le sommet du catalogue. Rapatrie le Haut-de-forme doré
    # et le Monocle du mentor, qui traînaient seuls au rayon légendaire.
    { name: "Haut-de-forme doré",  slot: "hat",   rarity: "legendary", price_diamonds: 1000, source: "shop",
      art: "gold_hat",     set: "L'intello" },
    { name: "Monocle du mentor",   slot: "eyes",  rarity: "legendary", price_diamonds: 1000, source: "shop",
      art: "monocle",      set: "L'intello" },
    { name: "Nœud papillon de velours", slot: "neck", rarity: "legendary", price_diamonds: 1000, source: "shop",
      art: "bowtie_lux",   set: "L'intello" },
    { name: "Livre et verre de vin", slot: "hands", rarity: "legendary", price_diamonds: 1000, source: "shop",
      art: "scholar_arms", set: "L'intello" },
    { name: "Chaussures cirées",   slot: "shoes", rarity: "legendary", price_diamonds: 1000, source: "shop",
      art: "dress_shoes",  set: "L'intello" },
    { name: "Arc-en-ciel",         slot: "aura",  rarity: "legendary", price_diamonds: nil, source: "set",
      emoji: "🌈",         set: "L'intello" },

    # Le chanceux (rare, 250 💎) — QUATRE pièces, trois d'entre elles ne sont qu'un paramétrage
    # de dessins existants (haut-de-forme, barbe, chaussure de ville).
    # ⚠️ Pas de pièce au COU : la barbe descend jusqu'à la base du fruit et couvrirait
    # entièrement ce qu'on y poserait (même raison que Le Père Noël).
    { name: "Chapeau de lutin",  slot: "hat",   rarity: "rare", price_diamonds: 250, source: "shop",
      art: "leprechaun_hat", set: "Le chanceux" },
    { name: "Barbe rousse",      slot: "eyes",  rarity: "rare", price_diamonds: 250, source: "shop",
      art: "red_beard",      set: "Le chanceux" },
    { name: "Pinte et chaudron", slot: "hands", rarity: "rare", price_diamonds: 250, source: "shop",
      art: "lucky_arms",     set: "Le chanceux" },
    { name: "Souliers à boucle", slot: "shoes", rarity: "rare", price_diamonds: 250, source: "shop",
      art: "buckle_shoes",   set: "Le chanceux" },
    { name: "Trèfle à quatre feuilles", slot: "aura", rarity: "rare", price_diamonds: nil, source: "set",
      emoji: "🍀",           set: "Le chanceux" },

    # La ballerine (rare, 250 💎) — rapatrie les Ballerines, qui traînaient seules au catalogue.
    # ⚠️ Son aura, le Cygne, est ÉPIQUE alors que les pièces sont rares : seules les auras
    # épiques et légendaires dérivent en fond (voir AuraBackground).
    { name: "Diadème",           slot: "hat",   rarity: "rare", price_diamonds: 250, source: "shop",
      art: "tiara",        set: "La ballerine" },
    { name: "Tutu",              slot: "neck",  rarity: "rare", price_diamonds: 250, source: "shop",
      art: "tutu",         set: "La ballerine" },
    { name: "Bras en couronne",  slot: "hands", rarity: "rare", price_diamonds: 250, source: "shop",
      art: "ballet_arms",  set: "La ballerine" },
    { name: "Ballerines",        slot: "shoes", rarity: "rare", price_diamonds: 250, source: "shop",
      art: "ballet",       set: "La ballerine" },
    { name: "Cygne",             slot: "aura",  rarity: "epic", price_diamonds: nil, source: "set",
      emoji: "🦢",         set: "La ballerine" },

    # Le fantôme (épique, 500 💎) — UNE SEULE PIÈCE : le drap suffit, il recouvre tout.
    # L'aura tombe donc dès l'achat (`UnlockSetAura` : « toutes les autres », il n'y en a pas).
    { name: "Drap de fantôme",   slot: "hat",  rarity: "epic", price_diamonds: 500, source: "shop",
      art: "ghost_sheet",  set: "Le fantôme" },
    { name: "Toile de sorcière", slot: "aura", rarity: "rare", price_diamonds: nil, source: "set",
      emoji: "🕸️",         set: "Le fantôme" },

    # Le plagiste (commune, 100 💎) — deuxième panoplie d'entrée, à côté du Coureur du dimanche.
    { name: "Casquette multicolore", slot: "hat",   rarity: "common", price_diamonds: 100, source: "shop",
      art: "beach_cap",     set: "Le plagiste" },
    { name: "Lunettes de soleil",    slot: "eyes",  rarity: "common", price_diamonds: 100, source: "shop",
      art: "beach_shades",  set: "Le plagiste" },
    { name: "Short de bain",         slot: "neck",  rarity: "common", price_diamonds: 100, source: "shop",
      art: "swim_shorts",   set: "Le plagiste" },
    { name: "Pelle et seau",         slot: "hands", rarity: "common", price_diamonds: 100, source: "shop",
      art: "beach_arms",    set: "Le plagiste" },
    { name: "Tongs de plage",        slot: "shoes", rarity: "common", price_diamonds: 100, source: "shop",
      art: "flip_flops",    set: "Le plagiste" },
    { name: "Château de sable",      slot: "aura",  rarity: "common", price_diamonds: nil, source: "set",
      art: "sandcastle",    set: "Le plagiste" },
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
