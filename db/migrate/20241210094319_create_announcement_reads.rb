class CreateAnnouncementReads < ActiveRecord::Migration[8.0]
  def change
    create_table :announcement_reads do |t|
      t.references :announcement, null: false, foreign_key: {on_delete: :cascade}
      t.references :contact, null: false, foreign_key: {on_delete: :cascade}
      t.datetime :read_at, null: false

      t.timestamps
    end
    add_index :announcement_reads, %i[announcement_id contact_id], unique: true
  end
end
