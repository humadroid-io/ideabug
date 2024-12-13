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

      context "GET index with segments" do
        setup do
          @segment = create(:segment, identifier: "region")
          @north_value = create(:segment_value, segment: @segment, val: "north")
          @south_value = create(:segment_value, segment: @segment, val: "south")

          # Announcement visible to northern contacts
          @north_announcement = create(:announcement, published_at: Time.current)
          @north_announcement.segment_values << @north_value

          # Announcement visible to southern contacts
          @south_announcement = create(:announcement, published_at: Time.current)
          @south_announcement.segment_values << @south_value

          # Announcement visible to all contacts (no segments)
          @public_announcement = create(:announcement, published_at: Time.current)
        end

        should "return announcements matching contact's segments" do
          @contact.segment_values << @north_value

          get api_v1_announcements_url,
            headers: {Authorization: "Bearer #{@token}"}

          assert_response :success
          json_response = JSON.parse(response.body)

          announcement_ids = json_response.map { |a| a["id"] }
          assert_includes announcement_ids, @north_announcement.id
          assert_includes announcement_ids, @public_announcement.id
          refute_includes announcement_ids, @south_announcement.id
        end

        should "return only public announcements when contact has no segments" do
          get api_v1_announcements_url,
            headers: {Authorization: "Bearer #{@token}"}

          assert_response :success
          json_response = JSON.parse(response.body)

          announcement_ids = json_response.map { |a| a["id"] }
          assert_includes announcement_ids, @public_announcement.id
          refute_includes announcement_ids, @north_announcement.id
          refute_includes announcement_ids, @south_announcement.id
        end

        should "return all matching announcements when contact has multiple segments" do
          @contact.segment_values << [@north_value, @south_value]

          get api_v1_announcements_url,
            headers: {Authorization: "Bearer #{@token}"}

          assert_response :success
          json_response = JSON.parse(response.body)

          announcement_ids = json_response.map { |a| a["id"] }
          assert_includes announcement_ids, @north_announcement.id
          assert_includes announcement_ids, @south_announcement.id
          assert_includes announcement_ids, @public_announcement.id
        end

        should "return announcement when it has multiple segments but contact matches any" do
          segment2 = create(:segment, identifier: "department")
          dept_value = create(:segment_value, segment: segment2, val: "sales")

          # Announcement requiring both north region AND sales department
          @multi_segment_announcement = create(:announcement, published_at: Time.current)
          @multi_segment_announcement.segment_values << [@north_value, dept_value]

          # Contact only has north region
          @contact.segment_values << @north_value

          get api_v1_announcements_url,
            headers: {Authorization: "Bearer #{@token}"}

          assert_response :success
          json_response = JSON.parse(response.body)

          announcement_ids = json_response.map { |a| a["id"] }
          assert_includes announcement_ids, @multi_segment_announcement.id
        end

        should "return announcement when contact has some of the announcement's segment values" do
          east = create(:segment_value, segment: @segment, val: "east")
          west = create(:segment_value, segment: @segment, val: "west")

          # Announcement assigned to all four values
          @announcement_all_regions = create(:announcement, published_at: Time.current)
          @announcement_all_regions.segment_values << [@north_value, @south_value, east, west]

          # Contact assigned to just two values
          @contact.segment_values << [@north_value, @south_value]

          get api_v1_announcements_url,
            headers: {Authorization: "Bearer #{@token}"}

          assert_response :success
          json_response = JSON.parse(response.body)

          announcement_ids = json_response.map { |a| a["id"] }
          assert_includes announcement_ids, @announcement_all_regions.id
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
