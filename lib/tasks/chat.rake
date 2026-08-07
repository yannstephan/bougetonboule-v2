# Remplir une conversation pour voir la pagination travailler.
#
# Le seed s'arrête à une douzaine de messages : c'est ce qu'il faut pour juger les séparateurs
# de journée, les bulles et les pastilles, mais on n'y voit RIEN de la pagination — tout tient
# dans la première page. Cette tâche existe pour l'autre besoin : remonter le fil, vérifier que
# les pages se recollent sans trou ni doublon, et que la vue ne bouge pas quand on greffe devant.
#
#   bin/rails chat:fill                           # 200 messages dans la conversation de partie
#   COUNT=500 CANAL=team bin/rails chat:fill      # ailleurs, et plus gros
#   bin/rails chat:clear                          # ne retire QUE les messages générés
#
# ⚠️ Tout vit dans un module : un `.rake` exécute son corps au niveau de l'objet principal, donc
# une constante ou une méthode posée là atterrit sur Object et peut cogner n'importe quoi.
module ChatFill
  # ⚠️ Marqueur invisible en fin de corps (espace de largeur nulle) : c'est lui qui rend
  # `chat:clear` sûr. Sans repère, nettoyer voudrait dire « supprimer les N derniers », et un
  # essai emporterait les messages du seed — ceux dont dépendent le point de lecture et les
  # pastilles de non-lus.
  MARK = "​".freeze

  OPENERS = [
    "12 km ce matin, les jambes tiennent",
    "Quelqu'un court ce soir ?",
    "King-Coco a repris des couleurs on dirait",
    "J'ai plus une boule, tout est parti dans la dernière salve",
    "Framboitrix est encore sous saladier, c'est pénible",
    "Sortie longue demain, 18 km prévus",
    "Le vent de face m'a coûté un quart de ma course 🌪️",
    "On se coordonne pour 20h ?",
    "Piège désamorcé, merci la jambe de bois 🦵",
    "Palier de meute gagné cette semaine 🐾",
    "Il me manque deux pièces pour finir la panoplie du loup",
    "Fractionné sur piste, 10 × 400. Je ne sens plus mes mollets.",
    "Coffre légendaire ce matin, je n'en reviens pas",
    "Plus que trois semaines avant la fin du mois",
    "Allure moyenne 5:12, content de moi",
    "J'ai gardé 30 🍑 pour la dernière ligne droite",
    "Réveil à 6h, il pleuvait. J'y suis allé quand même.",
    "Le second souffle leur a sauvé la partie, franchement"
  ].freeze

  REPLIES = [
    "Bien joué 👏", "Je suis dedans", "Pareil ici", "Ah oui quand même",
    "On va les avoir", "Compte sur moi", "Pas ce soir, demain plutôt",
    "Tu m'étonnes 😅", "Même pas peur", "Je garde mes boules pour la fin"
  ].freeze

  def self.conversation(game, canal)
    return game.general_conversation if canal.blank? || canal == "general"

    game.conversations.team_chats.first
  end

  def self.label(conv) = conv.kind == "general" ? "Partie" : "Équipe #{conv.team.name}"
end

namespace :chat do
  desc "Remplit une conversation de messages pour tester la pagination (COUNT, CANAL)"
  task fill: :environment do
    count = (ENV["COUNT"] || 200).to_i
    game  = Game.order(:id).last or abort "Aucune partie. Lance d'abord bin/rails db:seed."
    conv  = ChatFill.conversation(game, ENV["CANAL"]) or abort "Pas de conversation d'équipe."
    people = conv.kind == "general" ? game.memberships.to_a : conv.team.memberships.to_a
    abort "Personne dans cette conversation." if people.empty?

    # ⚠️ On remonte dans le PASSÉ à partir du plus ancien message existant. Le fil du seed reste
    # donc en bas, là où on l'a laissé, et tout ce qu'on ajoute est de l'historique à remonter.
    # Empiler par-dessus enterrerait le seed et gonflerait les pastilles de non-lus, qui sont
    # justement ce que le seed met en scène.
    cursor = conv.messages.minimum(:created_at) || Time.current

    ActiveRecord::Base.transaction do
      count.times do |i|
        cursor -= rand(4..40).minutes
        body = i.even? ? ChatFill::OPENERS.sample : ChatFill::REPLIES.sample
        Message.create!(conversation: conv, membership: people.sample,
                        body: "#{body}#{ChatFill::MARK}", created_at: cursor)
      end
    end

    puts "#{count} messages ajoutés dans « #{ChatFill.label(conv)} » " \
         "(#{conv.messages.count} au total), remontant jusqu'au #{cursor.strftime('%d/%m/%Y')}."
  end

  desc "Retire les messages générés par chat:fill (jamais ceux du seed)"
  task clear: :environment do
    gone = Message.where("body LIKE ?", "%#{ChatFill::MARK}").destroy_all.size
    puts "#{gone} messages générés retirés. Le seed est intact."
  end
end
