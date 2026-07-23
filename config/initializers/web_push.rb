# Clés VAPID pour le Web Push. Génère-les avec `bin/rails webpush:keys`
# puis mets-les dans les credentials (vapid.public_key / vapid.private_key) ou en ENV.
Rails.application.config.x.vapid = {
  public_key:  Rails.application.credentials.dig(:vapid, :public_key)  || ENV["VAPID_PUBLIC_KEY"],
  private_key: Rails.application.credentials.dig(:vapid, :private_key) || ENV["VAPID_PRIVATE_KEY"],
  subject:     ENV.fetch("VAPID_SUBJECT", "mailto:admin@bougetonboule.example")
}
