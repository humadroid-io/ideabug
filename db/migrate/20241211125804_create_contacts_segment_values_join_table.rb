class CreateContactsSegmentValuesJoinTable < ActiveRecord::Migration[8.0]
  def change
    create_join_table :contacts, :segment_values do |t|
      t.index [:contact_id, :segment_value_id], unique: true
    end
  end
end
