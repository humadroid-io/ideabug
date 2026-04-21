module Api
  module V1
    class AnnouncementsController < BaseController
      LIST_LIMIT = 10
      READ_WINDOW = 1.month

      before_action :find_announcement, only: %i[show read]

      def index
        announcements = announcement_scope
          .order(published_at: :desc)
          .limit(LIST_LIMIT)
          .to_a

        unread = Current.contact.announcements_opted_out? ? 0 : unread_announcement_ids.size
        response.headers["X-Ideabug-Unread"] = unread.to_s
        # Slim list — no rich-text body. The widget fetches /announcements/:id
        # for the body when it opens the modal.
        render json: AnnouncementBlueprint.render(announcements)
      end

      def show
        render json: AnnouncementBlueprint.render(@announcement, view: :detail)
      end

      def read
        @announcement.announcement_reads.find_or_create_by(contact: Current.contact) do |a|
          a.read_at = Time.current
        end

        render json: AnnouncementBlueprint.render(@announcement.reload, view: :detail)
      end

      def read_all
        unread_ids = unread_announcement_ids
        marked = mark_as_read(unread_ids)
        response.headers["X-Ideabug-Unread"] = "0"
        render json: {marked: marked}
      end

      def opt_out
        Current.contact.update!(announcements_opted_out: true)
        response.headers["X-Ideabug-Opted-Out"] = "true"
        response.headers["X-Ideabug-Unread"] = "0"
        render json: {opted_out: true}
      end

      def opt_in
        Current.contact.update!(announcements_opted_out: false)
        response.headers["X-Ideabug-Opted-Out"] = "false"
        render json: {opted_out: false}
      end

      private

      def announcement_scope
        Announcement
          .visible_to_contact(Current.contact)
          .select(Announcement.read_state_select_for(Current.contact, unread_cutoff: READ_WINDOW.ago))
      end

      def unread_announcement_ids
        Announcement
          .visible_to_contact(Current.contact)
          .where("published_at > ?", READ_WINDOW.ago)
          .where.not(id: AnnouncementRead.where(contact_id: Current.contact.id).select(:announcement_id))
          .pluck(:id)
      end

      def mark_as_read(ids)
        return 0 if ids.empty?
        now = Time.current
        rows = ids.map { |id| {announcement_id: id, contact_id: Current.contact.id, read_at: now, created_at: now, updated_at: now} }
        AnnouncementRead.insert_all(rows, unique_by: %i[announcement_id contact_id])
        ids.size
      end

      def find_announcement
        @announcement = announcement_scope.find(params[:id])
      end
    end
  end
end
