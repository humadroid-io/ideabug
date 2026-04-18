module Api
  module V1
    class RoadmapController < BaseController
      def index
        buckets = RoadmapPresenter.call
        render json: buckets.transform_values { |tickets| RoadmapTicketBlueprint.render_as_hash(tickets) }
      end
    end
  end
end
