class AddAnonymousIdentityToContacts < ActiveRecord::Migration[8.0]
  def up
    change_table :contacts, bulk: true do |t|
      t.string :anonymous_id
      t.boolean :announcements_opted_out, default: false, null: false
      t.datetime :last_seen_at
    end

    change_column_null :contacts, :external_id, true

    remove_index :contacts, :external_id
    add_index :contacts, :external_id, unique: true, where: "external_id IS NOT NULL"
    add_index :contacts, :anonymous_id, unique: true, where: "anonymous_id IS NOT NULL"

    execute <<~SQL
      ALTER TABLE contacts
      ADD CONSTRAINT contacts_identity_present
      CHECK (anonymous_id IS NOT NULL OR external_id IS NOT NULL)
    SQL
  end

  def down
    execute "ALTER TABLE contacts DROP CONSTRAINT IF EXISTS contacts_identity_present"

    remove_index :contacts, :anonymous_id
    remove_index :contacts, :external_id
    add_index :contacts, :external_id, unique: true

    change_column_null :contacts, :external_id, false

    change_table :contacts, bulk: true do |t|
      t.remove :last_seen_at
      t.remove :announcements_opted_out
      t.remove :anonymous_id
    end
  end
end
