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
          .visible_to_contact(contact)
          .where("published_at > ?", READ_WINDOW.ago)
          .where.not(id: AnnouncementRead.where(contact_id: contact.id).select(:announcement_id))
          .count
      end
    end
  end
end
