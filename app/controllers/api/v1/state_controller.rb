module Api
  module V1
    # Cheap heartbeat endpoint for the widget's background poll. Returns the
    # unread badge count + opt-out state without serializing the announcement
    # list. The widget hits this on every poll tick instead of /announcements.
    class StateController < BaseController
      READ_WINDOW = 1.month

      def show
        contact = Current.contact
        unread = contact.announcements_opted_out? ? 0 : self.class.unread_count_for(contact)

        response.headers["X-Ideabug-Unread"] = unread.to_s
        render json: {
          unread_count: unread,
          opted_out: contact.announcements_opted_out,
          contact_id: contact.id
        }
      end

      def self.unread_count_for(contact)
        Announcement
          .where("published_at > ?", READ_WINDOW.ago)
          .where.not(id: AnnouncementRead.where(contact_id: contact.id).select(:announcement_id))
          .where(
            "NOT EXISTS (
              SELECT 1 FROM announcements_segment_values
              WHERE announcements_segment_values.announcement_id = announcements.id
            ) OR EXISTS (
              SELECT 1 FROM announcements_segment_values asv
              WHERE asv.announcement_id = announcements.id
              AND asv.segment_value_id IN (
                SELECT segment_value_id
                FROM contacts_segment_values
                WHERE contact_id = ?
              )
            )",
            contact.id
          )
          .count
      end
    end
  end
end
