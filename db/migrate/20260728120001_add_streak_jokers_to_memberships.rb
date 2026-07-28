class AddStreakJokersToMemberships < ActiveRecord::Migration[8.1]
  def change
    add_column :memberships, :streak_jokers, :integer, default: 0, null: false
  end
end
