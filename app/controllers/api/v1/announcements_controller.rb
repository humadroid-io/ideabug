module Api
  module V1
    class AnnouncementsController < BaseController
      def index
        announcements = Announcement.all
        render json: AnnouncementBlueprint.render(announcements)
      end

      private
    end
  end
end
