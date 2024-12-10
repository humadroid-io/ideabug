class AddPublishedAtToAnnouncements < ActiveRecord::Migration[8.0]
  def change
    add_column :announcements, :published_at, :datetime
    up_only do
      Announcement.update_all("published_at = created_at")
    end
    change_column_null :announcements, :published_at, false
    add_index :announcements, :published_at
  end
end
