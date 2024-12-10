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
        Announcement
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
      end

      def find_announcement
        @announcement = announcement_scope.find(params[:id])
      end
    end
  end
end
