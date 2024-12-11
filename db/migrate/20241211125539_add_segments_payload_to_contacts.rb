class AddSegmentsPayloadToContacts < ActiveRecord::Migration[8.0]
  def change
    add_column :contacts, :segments_payload, :jsonb, default: {}
  end
end
