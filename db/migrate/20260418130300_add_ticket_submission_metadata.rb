class AddTicketSubmissionMetadata < ActiveRecord::Migration[8.0]
  def change
    change_table :tickets, bulk: true do |t|
      t.string :source, default: "admin", null: false
      t.jsonb :context, default: {}
    end

    add_index :tickets, :source
  end
end
