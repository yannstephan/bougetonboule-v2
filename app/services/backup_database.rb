# Sauvegarde de la base de jeu, en rotation datée sur le volume.
#
# ⚠️ **Portée exacte** : ceci protège de la FAUSSE MANŒUVRE — une suppression, une migration
# ratée, un bug découvert trois jours plus tard. Ça ne protège PAS de la perte du volume,
# puisque les copies vivent sur le même disque que l'original. Le jour où on veut couvrir ça,
# il n'y a qu'un point à brancher : envoyer le fichier rendu par `call` vers un stockage
# distant (Cloudflare R2, Backblaze…).
#
# Pas de cron système sur Fly : la tâche est planifiée par Solid Queue (config/recurring.yml),
# qui tourne dans Puma.
#
# On ne sauvegarde QUE la base de jeu (celle de la connexion courante). cache / queue / cable
# se reconstruisent seules : le cache est jetable, la file ne contient que du travail en
# attente, cable est éphémère. Les sauvegarder quadruplerait la place pour rien.
class BackupDatabase
  DIR = Rails.root.join("storage/backups")

  # ——— Pourquoi une rotation et pas un simple écrasement ———
  # Écraser la copie de la veille ne protège que du cas « le fichier a disparu à l'instant ».
  # Le cas réel le plus fréquent est « je découvre mardi qu'un truc a mal tourné samedi » :
  # avec un seul emplacement, la copie saine a déjà été remplacée par trois copies du problème.
  DAILY_KEPT  = 7 # les 7 dernières nuits
  WEEKLY_KEPT = 4 # + les 4 derniers lundis, pour pouvoir remonter à « avant » plus loin

  # Les copies ne sont PAS compressées, volontairement : une restauration se fait sous
  # stress, et un fichier .sqlite3 brut s'ouvre directement (`sqlite3 fichier`) pour vérifier
  # son contenu avant de l'installer. Le gain de place ne vaut pas cette perte de lisibilité.
  PREFIX = "production"

  Result = Struct.new(:path, :bytes, :pruned, keyword_init: true)

  def self.call(...) = new(...).call

  def initialize(now: Time.current)
    @now = now
  end

  def call
    FileUtils.mkdir_p(DIR)
    path = dated_path
    snapshot!(path)
    Result.new(path: path, bytes: File.size(path), pruned: prune!)
  end

  private

  attr_reader :now

  def dated_path = DIR.join("#{PREFIX}-#{now.strftime('%Y-%m-%d')}.sqlite3")

  def snapshot!(path)
    tmp = Pathname.new("#{path}.part")
    tmp.delete if tmp.exist?

    # `VACUUM INTO` prend un instantané COHÉRENT d'une base en cours d'écriture (et la
    # compacte au passage). Un `cp` sur une base vivante produit un fichier corrompu : le
    # WAL n'y est pas intégré.
    conn = ActiveRecord::Base.connection
    conn.execute("VACUUM INTO #{conn.quote(tmp.to_s)}")

    # Renommage atomique : un fichier daté n'apparaît que lorsqu'il est complet. Une
    # sauvegarde interrompue laisse un `.part`, jamais une demi-copie d'apparence valide.
    FileUtils.mv(tmp, path)
  end

  def prune!
    # Les noms sont en ISO : l'ordre lexicographique EST l'ordre chronologique.
    all      = Dir.glob(DIR.join("#{PREFIX}-*.sqlite3")).sort.reverse.map { |f| Pathname.new(f) }
    daily    = all.first(DAILY_KEPT)
    weekly   = (all - daily).select { |p| date_of(p)&.monday? }.first(WEEKLY_KEPT)
    doomed   = all - daily - weekly
    doomed.each(&:delete)
    doomed.size
  end

  def date_of(path)
    Date.parse(path.basename(".sqlite3").to_s.delete_prefix("#{PREFIX}-"))
  rescue Date::Error
    nil
  end
end
