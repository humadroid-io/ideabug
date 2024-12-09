class CreateSegments < ActiveRecord::Migration[8.0]
  def change
    create_table :segments do |t|
      t.string :identifier, null: false, index: {unique: true}
      t.boolean :allow_new_values, default: false

      t.timestamps
    end
  end
end
