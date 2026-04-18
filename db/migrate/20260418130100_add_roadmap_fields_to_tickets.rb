class AddRoadmapFieldsToTickets < ActiveRecord::Migration[8.0]
  def change
    change_table :tickets, bulk: true do |t|
      t.references :contact, foreign_key: true, null: true
      t.datetime :scheduled_for
      t.datetime :shipped_at
      t.boolean :public_on_roadmap, default: false, null: false
      t.integer :votes_count, default: 0, null: false
    end

    add_index :tickets, :scheduled_for
    add_index :tickets, :shipped_at
    add_index :tickets, [:classification, :status]
    add_index :tickets, [:public_on_roadmap, :classification]
  end
end
