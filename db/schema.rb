# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_07_24_170000) do
  create_table "actions", force: :cascade do |t|
    t.string "action_type", null: false
    t.integer "amount"
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "game_id", null: false
    t.integer "item_id"
    t.integer "membership_id", null: false
    t.bigint "target_id"
    t.string "target_type"
    t.datetime "updated_at", null: false
    t.index ["game_id"], name: "index_actions_on_game_id"
    t.index ["item_id"], name: "index_actions_on_item_id"
    t.index ["membership_id"], name: "index_actions_on_membership_id"
    t.index ["target_type", "target_id"], name: "index_actions_on_target_type_and_target_id"
  end

  create_table "avatars", force: :cascade do |t|
    t.string "base_color", default: "citron", null: false
    t.string "body_style", default: "default", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_avatars_on_user_id", unique: true
  end

  create_table "chests", force: :cascade do |t|
    t.integer "cosmetic_id"
    t.datetime "created_at", null: false
    t.integer "membership_id", null: false
    t.datetime "opened_at"
    t.string "rarity", default: "common", null: false
    t.integer "reward_diamonds", default: 0, null: false
    t.string "status", default: "sealed", null: false
    t.integer "training_id"
    t.datetime "updated_at", null: false
    t.index ["cosmetic_id"], name: "index_chests_on_cosmetic_id"
    t.index ["membership_id"], name: "index_chests_on_membership_id"
    t.index ["training_id"], name: "index_chests_on_training_id"
  end

  create_table "conversations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "game_id", null: false
    t.string "kind", default: "general", null: false
    t.integer "team_id"
    t.datetime "updated_at", null: false
    t.index ["game_id"], name: "index_conversations_on_game_id"
    t.index ["team_id"], name: "index_conversations_on_team_id"
  end

  create_table "cosmetics", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "emoji"
    t.string "name", null: false
    t.integer "price_diamonds"
    t.string "rarity", default: "common", null: false
    t.string "slot", null: false
    t.string "source", default: "shop", null: false
    t.datetime "updated_at", null: false
  end

  create_table "events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "location"
    t.string "name", null: false
    t.datetime "race_date"
    t.datetime "updated_at", null: false
    t.string "url"
  end

  create_table "games", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "ends_at"
    t.integer "event_id", null: false
    t.string "name", null: false
    t.datetime "starts_at"
    t.string "status", default: "upcoming", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_games_on_event_id"
  end

  create_table "items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "effect_type"
    t.boolean "miscellaneous", default: false, null: false
    t.string "name", null: false
    t.integer "price", default: 0, null: false
    t.datetime "updated_at", null: false
  end

  create_table "membership_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "item_id", null: false
    t.integer "membership_id", null: false
    t.datetime "updated_at", null: false
    t.boolean "used", default: false, null: false
    t.index ["item_id"], name: "index_membership_items_on_item_id"
    t.index ["membership_id"], name: "index_membership_items_on_membership_id"
  end

  create_table "memberships", force: :cascade do |t|
    t.integer "balls", default: 0, null: false
    t.integer "best_streak", default: 0, null: false
    t.datetime "created_at", null: false
    t.integer "game_id", null: false
    t.date "last_streak_week"
    t.string "role", default: "player", null: false
    t.integer "team_id", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.integer "weekly_streak", default: 0, null: false
    t.index ["game_id"], name: "index_memberships_on_game_id"
    t.index ["team_id"], name: "index_memberships_on_team_id"
    t.index ["user_id", "game_id"], name: "index_memberships_on_user_id_and_game_id", unique: true
    t.index ["user_id"], name: "index_memberships_on_user_id"
  end

  create_table "messages", force: :cascade do |t|
    t.text "body", null: false
    t.integer "conversation_id", null: false
    t.datetime "created_at", null: false
    t.integer "membership_id", null: false
    t.datetime "updated_at", null: false
    t.index ["conversation_id"], name: "index_messages_on_conversation_id"
    t.index ["membership_id"], name: "index_messages_on_membership_id"
  end

  create_table "monsters", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "hp", default: 1000, null: false
    t.integer "max_hp", default: 1000, null: false
    t.string "name", null: false
    t.datetime "protected_until"
    t.string "state", default: "healthy", null: false
    t.integer "team_id", null: false
    t.datetime "updated_at", null: false
    t.index ["team_id"], name: "index_monsters_on_team_id", unique: true
  end

  create_table "notifications", force: :cascade do |t|
    t.text "body"
    t.string "category", null: false
    t.datetime "created_at", null: false
    t.integer "game_id"
    t.json "payload"
    t.datetime "read_at"
    t.string "title"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["game_id"], name: "index_notifications_on_game_id"
    t.index ["user_id"], name: "index_notifications_on_user_id"
  end

  create_table "push_subscriptions", force: :cascade do |t|
    t.string "auth_key"
    t.datetime "created_at", null: false
    t.string "endpoint", null: false
    t.datetime "last_used_at"
    t.string "p256dh_key"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["endpoint"], name: "index_push_subscriptions_on_endpoint", unique: true
    t.index ["user_id"], name: "index_push_subscriptions_on_user_id"
  end

  create_table "rewards", force: :cascade do |t|
    t.integer "amount"
    t.integer "cosmetic_id"
    t.datetime "created_at", null: false
    t.integer "membership_id"
    t.string "period"
    t.string "reward_type", null: false
    t.string "source", null: false
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["cosmetic_id"], name: "index_rewards_on_cosmetic_id"
    t.index ["membership_id", "source", "period"], name: "index_rewards_on_membership_id_and_source_and_period", unique: true
    t.index ["membership_id"], name: "index_rewards_on_membership_id"
    t.index ["user_id"], name: "index_rewards_on_user_id"
  end

  create_table "special_days", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "date", null: false
    t.integer "game_id", null: false
    t.decimal "multiplier", precision: 4, scale: 2, default: "2.0", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["game_id"], name: "index_special_days_on_game_id"
  end

  create_table "team_effects", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "created_by_id"
    t.datetime "expires_at"
    t.string "kind", null: false
    t.decimal "modifier", precision: 5, scale: 2
    t.integer "team_id", null: false
    t.datetime "updated_at", null: false
    t.index ["team_id"], name: "index_team_effects_on_team_id"
  end

  create_table "teams", force: :cascade do |t|
    t.string "color"
    t.datetime "created_at", null: false
    t.integer "game_id", null: false
    t.decimal "multiplier", precision: 5, scale: 2, default: "1.0", null: false
    t.string "name", null: false
    t.integer "opponent_id"
    t.datetime "updated_at", null: false
    t.index ["game_id"], name: "index_teams_on_game_id"
    t.index ["opponent_id"], name: "index_teams_on_opponent_id"
  end

  create_table "trainings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "date", null: false
    t.integer "distance_meters", default: 0, null: false
    t.integer "membership_id", null: false
    t.decimal "score", precision: 6, scale: 1, default: "0.0", null: false
    t.integer "special_day_id"
    t.string "status", default: "pending", null: false
    t.string "strava_activity_id"
    t.datetime "updated_at", null: false
    t.index ["membership_id"], name: "index_trainings_on_membership_id"
    t.index ["special_day_id"], name: "index_trainings_on_special_day_id"
    t.index ["strava_activity_id"], name: "index_trainings_on_strava_activity_id"
  end

  create_table "user_cosmetics", force: :cascade do |t|
    t.datetime "acquired_at"
    t.integer "cosmetic_id", null: false
    t.datetime "created_at", null: false
    t.boolean "equipped", default: false, null: false
    t.integer "source_game_id"
    t.datetime "updated_at", null: false
    t.integer "user_id", null: false
    t.index ["cosmetic_id"], name: "index_user_cosmetics_on_cosmetic_id"
    t.index ["user_id", "cosmetic_id"], name: "index_user_cosmetics_on_user_id_and_cosmetic_id", unique: true
    t.index ["user_id"], name: "index_user_cosmetics_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "avatar_url"
    t.datetime "created_at", null: false
    t.integer "diamonds", default: 0, null: false
    t.string "email", null: false
    t.string "firstname"
    t.string "google_uid"
    t.string "lastname"
    t.string "password_digest"
    t.string "provider"
    t.datetime "strava_expires_at"
    t.string "strava_refresh_token"
    t.string "strava_token"
    t.string "strava_uid"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["google_uid"], name: "index_users_on_google_uid", unique: true
  end

  add_foreign_key "actions", "games"
  add_foreign_key "actions", "items"
  add_foreign_key "actions", "memberships"
  add_foreign_key "avatars", "users"
  add_foreign_key "chests", "cosmetics"
  add_foreign_key "chests", "memberships"
  add_foreign_key "chests", "trainings"
  add_foreign_key "conversations", "games"
  add_foreign_key "conversations", "teams"
  add_foreign_key "games", "events"
  add_foreign_key "membership_items", "items"
  add_foreign_key "membership_items", "memberships"
  add_foreign_key "memberships", "games"
  add_foreign_key "memberships", "teams"
  add_foreign_key "memberships", "users"
  add_foreign_key "messages", "conversations"
  add_foreign_key "messages", "memberships"
  add_foreign_key "monsters", "teams"
  add_foreign_key "notifications", "games"
  add_foreign_key "notifications", "users"
  add_foreign_key "push_subscriptions", "users"
  add_foreign_key "rewards", "cosmetics"
  add_foreign_key "rewards", "memberships"
  add_foreign_key "rewards", "users"
  add_foreign_key "special_days", "games"
  add_foreign_key "team_effects", "teams"
  add_foreign_key "teams", "games"
  add_foreign_key "trainings", "memberships"
  add_foreign_key "trainings", "special_days"
  add_foreign_key "user_cosmetics", "cosmetics"
  add_foreign_key "user_cosmetics", "users"
end
