require "test_helper"

module Api
  module V1
    class RoadmapControllerTest < ActionDispatch::IntegrationTest
      ANON_HEADER = "X-Ideabug-Anon-Id".freeze

      def setup
        @contact = create(:contact, :anonymous, anonymous_id: "ib_roadmap_caller_anon")
        @headers = {ANON_HEADER => @contact.anonymous_id}
      end

      test "buckets tickets into now/next/shipped/ideas" do
        in_progress = create(:ticket, :feature, status: :in_progress)
        scheduled = create(:ticket, :feature, scheduled_for: 2.weeks.from_now)
        shipped = create(:ticket, :feature, shipped_at: 3.days.ago, status: :completed)
        idea = create(:ticket, :feature)
        create(:ticket_vote, ticket: idea)
        # off-roadmap ticket
        create(:ticket, :feature, public_on_roadmap: false)

        get api_v1_roadmap_url, headers: @headers

        assert_response :success
        body = JSON.parse(response.body)
        assert_equal [in_progress.id], body["now"].map { |t| t["id"] }
        assert_equal [scheduled.id], body["next"].map { |t| t["id"] }
        assert_equal [shipped.id], body["shipped"].map { |t| t["id"] }
        assert_equal [idea.id], body["ideas"].map { |t| t["id"] }
      end
    end
  end
end
