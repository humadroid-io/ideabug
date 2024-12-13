module Api
  module V1
    class AnnouncementsController < BaseController
      before_action :find_announcement, only: %i[show read]
      def index
        limit = 3
        announcements = announcement_scope
          .order(published_at: :desc)
          .limit(limit)
        render json: AnnouncementBlueprint.render(announcements)
      end

      def show
        render json: AnnouncementBlueprint.render(@announcement)
      end

      def read
        @announcement.announcement_reads.find_or_create_by(contact: Current.contact) do |a|
          a.read_at = Time.current
        end

        render json: AnnouncementBlueprint.render(@announcement.reload)
      end

      private

      def announcement_scope
        base_scope = Announcement
          .select(
            'announcements.*,
                      CASE
                        WHEN announcement_reads.id IS NOT NULL THEN true
                        WHEN announcements.published_at > CURRENT_TIMESTAMP - INTERVAL \'1 month\' THEN false
                        ELSE true
                      END as read'
          )
          .left_joins(:announcement_reads)
          .where("announcement_reads.contact_id = ? OR announcement_reads.id IS NULL", Current.contact)

        base_scope
          .left_joins(:segment_values)
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
                    )
                  ",
            Current.contact.id
          )
          .distinct
      end

      def find_announcement
        @announcement = announcement_scope.find(params[:id])
      end
    end
  end
end
