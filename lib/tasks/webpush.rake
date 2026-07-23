namespace :webpush do
  desc "Génère une paire de clés VAPID (à mettre en VAPID_PUBLIC_KEY / VAPID_PRIVATE_KEY)"
  task keys: :environment do
    key = WebPush.generate_key
    puts "VAPID_PUBLIC_KEY=#{key.public_key}"
    puts "VAPID_PRIVATE_KEY=#{key.private_key}"
  end
end
