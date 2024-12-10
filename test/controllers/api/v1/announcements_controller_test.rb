require "test_helper"

module Api
  module V1
    class AnnouncementsControllerTest < ActionDispatch::IntegrationTest
      def setup
        @contact = create(:contact)
        @token = JwtCredentialService.generate_token(@contact)
        @announcement = create(:announcement, published_at: Time.current)
        Current.contact = @contact
      end

      context "GET index" do
        should "return announcements with valid token" do
          get api_v1_announcements_url,
            headers: {Authorization: "Bearer #{@token}"}

          assert_response :success
          json_response = JSON.parse(response.body)
          assert_kind_of Array, json_response
          assert_equal 1, json_response.length
        end

        should "respect the limit of 3 announcements" do
          create_list(:announcement, 4, published_at: Time.current)

          get api_v1_announcements_url,
            headers: {Authorization: "Bearer #{@token}"}

          assert_response :success
          json_response = JSON.parse(response.body)
          assert_equal 3, json_response.length
        end

        should "not get index without token" do
          get api_v1_announcements_url
          assert_response :unauthorized
        end

        should "not get index with invalid token" do
          get api_v1_announcements_url,
            headers: {Authorization: "Bearer invalid_token"}

          assert_response :unauthorized
        end
      end

      context "GET show" do
        should "return single announcement" do
          get api_v1_announcement_url(@announcement),
            headers: {Authorization: "Bearer #{@token}"}

          assert_response :success
          json_response = JSON.parse(response.body)
          assert_equal @announcement.title, json_response["title"]
        end
      end

      context "POST read" do
        should "mark announcement as read" do
          assert_difference "AnnouncementRead.count" do
            post read_api_v1_announcement_url(@announcement),
              headers: {Authorization: "Bearer #{@token}"}
          end

          assert_response :success
          json_response = JSON.parse(response.body)
          assert json_response["read"]
        end

        should "not create duplicate read entries" do
          create(:announcement_read, announcement: @announcement, contact: @contact)

          assert_no_difference "AnnouncementRead.count" do
            post read_api_v1_announcement_url(@announcement),
              headers: {Authorization: "Bearer #{@token}"}
          end

          assert_response :success
        end
      end

      def teardown
        Current.contact = nil
      end
    end
  end
end
