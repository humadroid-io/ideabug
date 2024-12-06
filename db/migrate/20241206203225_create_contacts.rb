class CreateContacts < ActiveRecord::Migration[8.0]
  def change
    create_table :contacts do |t|
      t.string :external_id, null: false, index: {unique: true}
      t.jsonb :info_payload, default: {}

      t.timestamps
    end
  end
end
