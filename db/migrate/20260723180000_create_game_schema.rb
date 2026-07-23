class CreateGameSchema < ActiveRecord::Migration[8.1]
  def change
    # --- Joueurs (niveau compte, persistant entre parties) ---
    create_table :users do |t|
      t.string   :firstname
      t.string   :lastname
      t.string   :email, null: false
      t.string   :password_digest
      t.string   :strava_uid
      t.string   :strava_token
      t.string   :strava_refresh_token
      t.datetime :strava_expires_at
      t.integer  :diamonds, null: false, default: 0
      t.timestamps
    end
    add_index :users, :email, unique: true

    create_table :avatars do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string :body_style, null: false, default: "default"
      t.string :base_color, null: false, default: "citron"
      t.timestamps
    end

    create_table :cosmetics do |t|
      t.string  :name, null: false
      t.string  :slot, null: false           # base / hat / eyes / outfit / aura
      t.string  :rarity, null: false, default: "common"
      t.integer :price_diamonds               # nullable = non achetable en boutique
      t.string  :source, null: false, default: "shop"  # shop / drop / event / rank
      t.timestamps
    end

    create_table :user_cosmetics do |t|
      t.references :user, null: false, foreign_key: true
      t.references :cosmetic, null: false, foreign_key: true
      t.boolean  :equipped, null: false, default: false
      t.integer  :source_game_id             # où il a été gagné (pas de FK : circulaire)
      t.datetime :acquired_at
      t.timestamps
    end
    add_index :user_cosmetics, [:user_id, :cosmetic_id], unique: true

    create_table :push_subscriptions do |t|
      t.references :user, null: false, foreign_key: true
      t.string   :endpoint, null: false
      t.string   :p256dh_key
      t.string   :auth_key
      t.string   :user_agent
      t.datetime :last_used_at
      t.timestamps
    end
    add_index :push_subscriptions, :endpoint, unique: true

    # --- Structure d'une partie ---
    create_table :events do |t|
      t.string   :name, null: false
      t.datetime :race_date
      t.string   :location
      t.string   :url
      t.timestamps
    end

    create_table :games do |t|
      t.references :event, null: false, foreign_key: true
      t.string   :name, null: false
      t.datetime :starts_at
      t.datetime :ends_at
      t.string   :status, null: false, default: "upcoming"  # upcoming / active / finished
      t.timestamps
    end

    create_table :teams do |t|
      t.references :game, null: false, foreign_key: true
      t.string  :name, null: false
      t.string  :color
      t.decimal :multiplier, precision: 5, scale: 2, null: false, default: 1
      t.integer :opponent_id                 # auto-référence (pas de FK : circulaire)
      t.timestamps
    end
    add_index :teams, :opponent_id

    create_table :monsters do |t|
      t.references :team, null: false, foreign_key: true, index: { unique: true }
      t.string   :name, null: false
      t.integer  :hp, null: false, default: 1000
      t.integer  :max_hp, null: false, default: 1000
      t.string   :state, null: false, default: "healthy"
      t.datetime :protected_until
      t.timestamps
    end

    create_table :team_effects do |t|
      t.references :team, null: false, foreign_key: true
      t.string   :kind, null: false          # back_wind / face_wind / shield
      t.decimal  :modifier, precision: 5, scale: 2
      t.datetime :expires_at
      t.integer  :created_by_id               # membership auteur (pas de FK)
      t.timestamps
    end

    create_table :special_days do |t|
      t.references :game, null: false, foreign_key: true
      t.string  :name, null: false
      t.date    :date, null: false
      t.decimal :multiplier, precision: 4, scale: 2, null: false, default: 2
      t.timestamps
    end

    # --- Participation d'un joueur à une partie ---
    create_table :memberships do |t|
      t.references :user, null: false, foreign_key: true
      t.references :game, null: false, foreign_key: true
      t.references :team, null: false, foreign_key: true
      t.integer :balls, null: false, default: 0
      t.integer :weekly_streak, null: false, default: 0
      t.integer :best_streak, null: false, default: 0
      t.date    :last_streak_week
      t.string  :role, null: false, default: "player"  # player / admin
      t.timestamps
    end
    add_index :memberships, [:user_id, :game_id], unique: true

    create_table :trainings do |t|
      t.references :membership, null: false, foreign_key: true
      t.references :special_day, null: true, foreign_key: true
      t.datetime :date, null: false
      t.integer  :distance_meters, null: false, default: 0
      t.decimal  :score, precision: 6, scale: 1, null: false, default: 0
      t.string   :status, null: false, default: "pending"  # pending/verified/rejected/trapped/protected
      t.string   :strava_activity_id
      t.timestamps
    end
    add_index :trainings, :strava_activity_id

    # --- Économie & combat ---
    create_table :items do |t|
      t.string  :name, null: false
      t.integer :price, null: false, default: 0
      t.text    :description
      t.string  :effect_type
      t.boolean :miscellaneous, null: false, default: false
      t.timestamps
    end

    create_table :membership_items do |t|
      t.references :membership, null: false, foreign_key: true
      t.references :item, null: false, foreign_key: true
      t.boolean :used, null: false, default: false
      t.timestamps
    end

    create_table :actions do |t|
      t.references :game, null: false, foreign_key: true
      t.references :membership, null: false, foreign_key: true
      t.references :item, null: true, foreign_key: true
      t.string  :action_type, null: false    # attack / heal / use_item
      t.string  :target_type                  # Monster / Membership (polymorphe)
      t.bigint  :target_id
      t.integer :amount
      t.text    :description
      t.timestamps
    end
    add_index :actions, [:target_type, :target_id]

    create_table :chests do |t|
      t.references :membership, null: false, foreign_key: true
      t.references :training, null: true, foreign_key: true
      t.references :cosmetic, null: true, foreign_key: true
      t.string   :rarity, null: false, default: "common"
      t.string   :status, null: false, default: "sealed"  # sealed / opened
      t.integer  :reward_diamonds, null: false, default: 0
      t.datetime :opened_at
      t.timestamps
    end

    create_table :rewards do |t|
      t.references :user, null: false, foreign_key: true
      t.references :membership, null: true, foreign_key: true
      t.references :cosmetic, null: true, foreign_key: true
      t.string  :source, null: false          # streak / special_day / chest / rank / admin
      t.string  :reward_type, null: false      # diamonds / cosmetic / balls
      t.integer :amount
      t.timestamps
    end

    # --- Social ---
    create_table :conversations do |t|
      t.references :game, null: false, foreign_key: true
      t.string :kind, null: false, default: "general"  # general / team
      t.references :team, null: true, foreign_key: true
      t.timestamps
    end

    create_table :messages do |t|
      t.references :conversation, null: false, foreign_key: true
      t.references :membership, null: false, foreign_key: true
      t.text :body, null: false
      t.timestamps
    end

    create_table :notifications do |t|
      t.references :user, null: false, foreign_key: true
      t.references :game, null: true, foreign_key: true
      t.string   :category, null: false       # attacked / healed / streak / chest / message ...
      t.string   :title
      t.text     :body
      t.json     :payload
      t.datetime :read_at
      t.timestamps
    end
  end
end
