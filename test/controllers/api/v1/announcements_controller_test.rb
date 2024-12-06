require "test_helper"

module Api
  module V1
    class AnnouncementsControllerTest < ActionDispatch::IntegrationTest
      def setup
        @user = create(:user)
        @token = JwtCredentialService.generate_token(@user)
        @announcement = create(:announcement)
      end

      test "should get index with valid token" do
        get api_v1_announcements_url,
          headers: {Authorization: "Bearer #{@token}"}

        assert_response :success
        json_response = JSON.parse(response.body)
        assert_kind_of Array, json_response
      end

      test "should not get index without token" do
        get api_v1_announcements_url
        assert_response :unauthorized
      end

      test "should not get index with invalid token" do
        get api_v1_announcements_url,
          headers: {Authorization: "Bearer invalid_token"}

        assert_response :unauthorized
      end

      test "should not get index with expired token" do
        travel_to(2.hours.from_now) do
          get api_v1_announcements_url,
            headers: {Authorization: "Bearer #{@token}"}

          assert_response :unauthorized
          json_response = JSON.parse(response.body)
          assert_includes json_response["error"], "expired"
        end
      end
    end
  end
end
