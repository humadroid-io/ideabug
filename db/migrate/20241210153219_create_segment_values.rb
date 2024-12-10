class CreateSegmentValues < ActiveRecord::Migration[8.0]
  def change
    create_table :segment_values do |t|
      t.references :segment, null: false, foreign_key: {on_delete: :cascade}
      t.string :val

      t.timestamps
    end
  end
end
