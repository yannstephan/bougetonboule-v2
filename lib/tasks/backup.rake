require "sqlite3"
require "fileutils"

namespace :backup do
  desc "Sauvegarde la base de jeu maintenant (rotation datée dans storage/backups)"
  task now: :environment do
    r = BackupDatabase.call
    puts "✅ #{r.path}"
    puts "   #{(r.bytes / 1024.0).round} Ko · #{r.pruned} ancienne(s) copie(s) supprimée(s)"
  end

  desc "Liste les sauvegardes disponibles"
  task list: :environment do
    files = Dir.glob(BackupDatabase::DIR.join("*.sqlite3")).sort.reverse
    abort "Aucune sauvegarde dans #{BackupDatabase::DIR}." if files.empty?
    puts "#{files.size} sauvegarde(s) — rétention : #{BackupDatabase::DAILY_KEPT} nuits " \
         "+ #{BackupDatabase::WEEKLY_KEPT} lundis"
    files.each do |f|
      puts format("  %-28s %8s Ko   %s", File.basename(f), (File.size(f) / 1024.0).round,
                  File.mtime(f).strftime("%d/%m/%Y %H:%M"))
    end
  end

  # ——— LE test de restauration ———
  # Non destructif : on ouvre la copie et on vérifie qu'elle est saine, complète et au bon
  # schéma, SANS toucher à la base en service. C'est ce qu'il faut lancer régulièrement :
  # une sauvegarde jamais vérifiée n'est pas une sauvegarde.
  desc "Vérifie une sauvegarde (FILE=… ou la plus récente) — ne touche à rien"
  task verify: :environment do
    file = ENV["FILE"] || Dir.glob(BackupDatabase::DIR.join("*.sqlite3")).max
    abort "Aucune sauvegarde à vérifier." if file.nil?
    abort "Introuvable : #{file}" unless File.exist?(file)
    puts "🔍 #{file} (#{(File.size(file) / 1024.0).round} Ko)"

    ok = true
    db = SQLite3::Database.new(file, readonly: true)

    check = db.get_first_value("PRAGMA integrity_check")
    puts(check == "ok" ? "   ✅ intégrité : ok" : "   ❌ intégrité : #{check}")
    ok &&= (check == "ok")

    # Le schéma doit correspondre à celui qu'attend le code, sinon la copie est restaurable
    # mais l'app ne démarrera pas dessus.
    backup_version  = db.get_first_value("SELECT MAX(version) FROM schema_migrations")
    current_version = ActiveRecord::Base.connection
      .select_value("SELECT MAX(version) FROM schema_migrations")
    same = backup_version == current_version
    puts "   #{same ? '✅' : '⚠️ '} schéma : #{backup_version}#{same ? '' : " (base en service : #{current_version})"}"

    # Contenu : une sauvegarde techniquement saine mais vide ne vaut rien.
    %w[users memberships trainings actions rewards messages].each do |table|
      count = db.get_first_value("SELECT COUNT(*) FROM #{table}")
      puts format("   %-14s %6d ligne(s)", table, count)
    rescue SQLite3::SQLException => e
      puts "   ❌ #{table} : #{e.message}"
      ok = false
    end

    db.close
    puts ok ? "\n✅ Sauvegarde exploitable." : "\n❌ Sauvegarde SUSPECTE — ne pas s'y fier."
    exit(1) unless ok
  end

  desc "Restaure une sauvegarde par-dessus la base en service (FILE=… CONFIRM=oui)"
  task restore: :environment do
    file = ENV.fetch("FILE") { abort "FILE=storage/backups/production-AAAA-MM-JJ.sqlite3 requis" }
    abort "Introuvable : #{file}" unless File.exist?(file)

    target = Rails.root.join(ActiveRecord::Base.connection_db_config.database).to_s

    unless ENV["CONFIRM"] == "oui"
      puts <<~AVERTISSEMENT
        ⚠️  Cette commande REMPLACE la base en service.
            source : #{file}
            cible  : #{target}

            Arrête l'app d'abord (`fly machine stop`), sinon Puma écrit pendant la bascule.
            La base actuelle sera mise de côté, pas supprimée.

            Relance avec : CONFIRM=oui FILE=#{file} bin/rails backup:restore
      AVERTISSEMENT
      exit 1
    end

    # On vérifie AVANT de toucher à quoi que ce soit.
    check = SQLite3::Database.new(file, readonly: true).get_first_value("PRAGMA integrity_check")
    abort "❌ La sauvegarde est corrompue (#{check}) — restauration annulée." unless check == "ok"

    stamp = Time.current.strftime("%Y%m%d-%H%M%S")
    if File.exist?(target)
      FileUtils.mv(target, "#{target}.avant-restauration-#{stamp}")
      puts "↪️  base actuelle mise de côté : #{File.basename(target)}.avant-restauration-#{stamp}"
    end

    # ⚠️ Indispensable : un WAL resté là appartient à l'ANCIENNE base. SQLite le rejouerait
    # par-dessus le fichier restauré et le corromprait.
    [ "#{target}-wal", "#{target}-shm" ].each { |f| File.delete(f) if File.exist?(f) }

    FileUtils.cp(file, target)
    puts "✅ Restauré. Redémarre l'app (`fly machine start`) puis vérifie le Hub."
  end
end
