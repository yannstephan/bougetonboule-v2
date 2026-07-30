# Tente de faire tomber un coffre à l'import d'une course scorée (voir GameRules).
# Garde-fous : max 1 coffre/jour par participation ; pity : coffre garanti après
# CHEST_PITY_RUNS courses scorées sans drop. Le contenu (💎 + éventuel cosmétique
# non possédé) est tiré au moment du drop et stocké sur le coffre — l'ouverture ne
# fait que le révéler.
class DropChest
  LABELS = { "common" => "commun", "rare" => "rare", "epic" => "épique", "legendary" => "légendaire" }.freeze

  def self.call(training) = new(training).call

  def initialize(training)
    @t = training
    @m = training.membership
  end

  def call
    return unless @t.status.in?(%w[verified protected]) && @t.score.to_i.positive?
    return if @m.chests.where(created_at: Date.current.all_day).exists?
    return unless rand < GameRules::CHEST_DROP_CHANCE || pity?

    rarity = roll_rarity
    chest = @m.chests.create!(
      training: @t, rarity:,
      reward_diamonds: GameRules::CHEST_DIAMONDS.fetch(rarity),
      cosmetic: maybe_cosmetic(rarity)
    )
    Notification.create!(
      user: @m.user, game: @m.game, category: "chest", importance: "important",
      title: "🎁 Tu as trouvé un coffre #{LABELS.fetch(rarity)} !",
      body: "Ta course de #{@t.distance_km.round(1)} km cachait un coffre. Ouvre-le sur le Hub !"
    )
    chest
  end

  private

  # Courses scorées depuis le dernier coffre (ou depuis toujours s'il n'y en a jamais eu).
  def pity?
    since = @m.chests.maximum(:created_at)
    runs = @m.trainings.where(status: %w[verified protected]).where(score: 1..)
    runs = runs.where(created_at: since..) if since
    runs.count >= GameRules::CHEST_PITY_RUNS
  end

  def roll_rarity
    draw = rand(GameRules::CHEST_RARITY_WEIGHTS.values.sum)
    GameRules::CHEST_RARITY_WEIGHTS.each do |rarity, weight|
      return rarity if draw < weight
      draw -= weight
    end
    "common"
  end

  def maybe_cosmetic(rarity)
    return nil unless rand < GameRules::CHEST_COSMETIC_CHANCE.fetch(rarity)

    Cosmetic.available.where.not(id: @m.user.user_cosmetics.select(:cosmetic_id)).order("RANDOM()").first
  end
end
