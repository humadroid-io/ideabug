class CreateAnnouncementsSegmentValuesJoinTable < ActiveRecord::Migration[8.0]
  def change
    create_join_table :announcements, :segment_values do |t|
      t.index [:announcement_id, :segment_value_id], unique: true
    end
  end
end
