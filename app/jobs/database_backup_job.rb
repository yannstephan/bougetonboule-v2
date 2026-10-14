# Sauvegarde nocturne de la base de jeu (voir BackupDatabase).
# Planifiée par Solid Queue dans config/recurring.yml — Fly n'a pas de cron système.
class DatabaseBackupJob < ApplicationJob
  queue_as :default

  def perform
    result = BackupDatabase.call
    Rails.logger.info(
      "[Backup] #{result.path} — #{(result.bytes / 1024.0).round} Ko, " \
      "#{result.pruned} ancienne(s) copie(s) supprimée(s)"
    )
  end
end
