class CreateTicketVotes < ActiveRecord::Migration[8.0]
  def change
    create_table :ticket_votes do |t|
      t.references :ticket, null: false, foreign_key: {on_delete: :cascade}
      t.references :contact, null: false, foreign_key: {on_delete: :cascade}
      t.datetime :voted_at, null: false
      t.timestamps
    end

    add_index :ticket_votes, [:ticket_id, :contact_id], unique: true

    reversible do |dir|
      dir.up do
        Ticket.reset_column_information
        Ticket.find_each { |t| Ticket.reset_counters(t.id, :ticket_votes) }
      end
    end
  end
end
