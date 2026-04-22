require "test_helper"

module Api
  module V1
    class AnnouncementsControllerTest < ActionDispatch::IntegrationTest
      def setup
        @contact = create(:contact)
        @token = JwtTestIssuer.generate_token(@contact)
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

        should "respect the LIST_LIMIT" do
          create_list(:announcement, Api::V1::AnnouncementsController::LIST_LIMIT + 2, published_at: Time.current)

          get api_v1_announcements_url,
            headers: {Authorization: "Bearer #{@token}"}

          assert_response :success
          json_response = JSON.parse(response.body)
          assert_equal Api::V1::AnnouncementsController::LIST_LIMIT, json_response.length
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

        should "hide announcements with a future published_at" do
          scheduled = create(:announcement, published_at: 1.day.from_now, title: "Scheduled")

          get api_v1_announcements_url,
            headers: {Authorization: "Bearer #{@token}"}

          assert_response :success
          ids = JSON.parse(response.body).pluck("id")
          assert_includes ids, @announcement.id
          refute_includes ids, scheduled.id
          assert_equal "1", response.headers["X-Ideabug-Unread"]
        end

        should "return announcements unread by the current contact even when another contact read them" do
          other_contact = create(:contact)
          create(:announcement_read, announcement: @announcement, contact: other_contact)

          get api_v1_announcements_url,
            headers: {Authorization: "Bearer #{@token}"}

          assert_response :success
          json_response = JSON.parse(response.body)

          assert_equal [@announcement.id], json_response.pluck("id")
          assert_equal false, json_response.first["read"]
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

          announcement_ids = json_response.pluck("id")
          assert_includes announcement_ids, @north_announcement.id
          assert_includes announcement_ids, @public_announcement.id
          refute_includes announcement_ids, @south_announcement.id
        end

        should "return only public announcements when contact has no segments" do
          get api_v1_announcements_url,
            headers: {Authorization: "Bearer #{@token}"}

          assert_response :success
          json_response = JSON.parse(response.body)

          announcement_ids = json_response.pluck("id")
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

          announcement_ids = json_response.pluck("id")
          assert_includes announcement_ids, @north_announcement.id
          assert_includes announcement_ids, @south_announcement.id
          assert_includes announcement_ids, @public_announcement.id
        end

        should "hide an announcement unless the contact matches every targeted segment" do
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

          announcement_ids = json_response.pluck("id")
          refute_includes announcement_ids, @multi_segment_announcement.id
        end

        should "return an announcement when the contact matches every targeted segment" do
          segment2 = create(:segment, identifier: "department")
          dept_value = create(:segment_value, segment: segment2, val: "sales")

          @multi_segment_announcement = create(:announcement, published_at: Time.current)
          @multi_segment_announcement.segment_values << [@north_value, dept_value]
          @contact.segment_values << [@north_value, dept_value]

          get api_v1_announcements_url,
            headers: {Authorization: "Bearer #{@token}"}

          assert_response :success
          json_response = JSON.parse(response.body)

          announcement_ids = json_response.pluck("id")
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

          announcement_ids = json_response.pluck("id")
          assert_includes announcement_ids, @announcement_all_regions.id
        end

        should "set unread header based only on announcements visible to the contact" do
          get api_v1_announcements_url,
            headers: {Authorization: "Bearer #{@token}"}

          assert_response :success
          assert_equal "2", response.headers["X-Ideabug-Unread"]
        end
      end

      context "GET show" do
        should "404 for a scheduled (future) announcement" do
          scheduled = create(:announcement, published_at: 1.day.from_now)

          get api_v1_announcement_url(scheduled),
            headers: {Authorization: "Bearer #{@token}"}

          assert_response :not_found
        end

        should "return single announcement with content" do
          @announcement.content = "<p>Long form body</p>"
          @announcement.save!

          get api_v1_announcement_url(@announcement),
            headers: {Authorization: "Bearer #{@token}"}

          assert_response :success
          json_response = JSON.parse(response.body)
          assert_equal @announcement.title, json_response["title"]
          assert_includes json_response["content"], "Long form body"
        end

        should "return announcements another contact has already read" do
          other_contact = create(:contact)
          create(:announcement_read, announcement: @announcement, contact: other_contact)

          get api_v1_announcement_url(@announcement),
            headers: {Authorization: "Bearer #{@token}"}

          assert_response :success
          json_response = JSON.parse(response.body)
          assert_equal @announcement.id, json_response["id"]
          assert_equal false, json_response["read"]
        end
      end

      context "lazy-load contract" do
        should "GET index does NOT serialize the rich-text body" do
          @announcement.content = "<p>Heavy body</p>"
          @announcement.save!

          get api_v1_announcements_url, headers: {Authorization: "Bearer #{@token}"}
          json_response = JSON.parse(response.body)
          refute json_response.first.key?("content"), "list should be slim"
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

      context "POST read_all" do
        should "mark all unread announcements within window as read" do
          create_list(:announcement, 3, published_at: 1.week.ago)
          assert_difference "AnnouncementRead.where(contact_id: @contact.id).count", 4 do
            post read_all_api_v1_announcements_url,
              headers: {Authorization: "Bearer #{@token}"}
          end

          assert_response :success
          body = JSON.parse(response.body)
          assert_equal 4, body["marked"]
          assert_equal "0", response.headers["X-Ideabug-Unread"]
        end

        should "be a no-op when nothing unread" do
          create(:announcement_read, announcement: @announcement, contact: @contact)
          assert_no_difference "AnnouncementRead.count" do
            post read_all_api_v1_announcements_url,
              headers: {Authorization: "Bearer #{@token}"}
          end
        end
      end

      context "POST opt_out / opt_in" do
        should "set the contact's opted_out flag and zero the unread header" do
          create_list(:announcement, 2, published_at: Time.current)

          post opt_out_api_v1_announcements_url, headers: {Authorization: "Bearer #{@token}"}
          assert_response :success
          assert @contact.reload.announcements_opted_out
          assert_equal "true", response.headers["X-Ideabug-Opted-Out"]

          # Index still returns announcements but unread header is 0
          get api_v1_announcements_url, headers: {Authorization: "Bearer #{@token}"}
          assert_equal 3, JSON.parse(response.body).length
          assert_equal "0", response.headers["X-Ideabug-Unread"]

          post opt_in_api_v1_announcements_url, headers: {Authorization: "Bearer #{@token}"}
          assert_response :success
          refute @contact.reload.announcements_opted_out
        end
      end

      context "headers" do
        should "set X-Ideabug-Unread on index" do
          get api_v1_announcements_url, headers: {Authorization: "Bearer #{@token}"}
          # 1 unread (the @announcement created in setup)
          assert_equal "1", response.headers["X-Ideabug-Unread"]
        end
      end

      def teardown
        Current.contact = nil
      end
    end
  end
end
