require "test_helper"

module Api
  module V1
    class StateControllerTest < ActionDispatch::IntegrationTest
      ANON_HEADER = "X-Ideabug-Anon-Id".freeze

      setup do
        @contact = create(:contact, :anonymous)
        @headers = {ANON_HEADER => @contact.anonymous_id}
      end

      test "returns unread count + opted_out for the current contact" do
        create_list(:announcement, 3, published_at: 2.days.ago)

        get api_v1_state_url, headers: @headers

        assert_response :success
        body = JSON.parse(response.body)
        assert_equal 3, body["unread_count"]
        assert_equal false, body["opted_out"]
        assert_equal "3", response.headers["X-Ideabug-Unread"]
      end

      test "excludes announcements with a future published_at from the unread count" do
        create_list(:announcement, 2, published_at: 2.days.ago)
        create(:announcement, published_at: 1.day.from_now)

        get api_v1_state_url, headers: @headers

        assert_response :success
        body = JSON.parse(response.body)
        assert_equal 2, body["unread_count"]
        assert_equal "2", response.headers["X-Ideabug-Unread"]
      end

      test "reports zero unread when the contact is opted out" do
        create_list(:announcement, 2, published_at: 2.days.ago)
        @contact.update!(announcements_opted_out: true)

        get api_v1_state_url, headers: @headers

        body = JSON.parse(response.body)
        assert_equal 0, body["unread_count"]
        assert_equal true, body["opted_out"]
      end

      test "counts only announcements that match every targeted segment" do
        region = create(:segment, identifier: "region")
        department = create(:segment, identifier: "department")
        north = create(:segment_value, segment: region, val: "north")
        sales = create(:segment_value, segment: department, val: "sales")
        targeted = create(:announcement, published_at: 2.days.ago)
        targeted.segment_values << [north, sales]
        @contact.segment_values << north

        get api_v1_state_url, headers: @headers

        assert_response :success
        body = JSON.parse(response.body)
        assert_equal 0, body["unread_count"]
        assert_equal "0", response.headers["X-Ideabug-Unread"]
      end
    end
  end
end
