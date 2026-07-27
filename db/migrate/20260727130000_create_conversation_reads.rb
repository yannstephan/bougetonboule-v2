class CreateConversationReads < ActiveRecord::Migration[8.1]
  # Marque, par participation et par conversation, la date du dernier message lu.
  # Sert à afficher la pastille de messages non lus sur l'onglet Chat.
  def change
    create_table :conversation_reads do |t|
      t.references :membership,   null: false, foreign_key: true
      t.references :conversation, null: false, foreign_key: true
      t.datetime   :last_read_at, null: false
      t.timestamps
    end
    add_index :conversation_reads, %i[membership_id conversation_id], unique: true
  end
end
