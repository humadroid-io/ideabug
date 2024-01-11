class CreateTickets < ActiveRecord::Migration[7.1]
  def change
    create_table :tickets do |t|
      t.string :title
      t.text :description
      t.integer :status, default: 0
      t.integer :classification, default: 0

      t.timestamps
    end
  end
end
