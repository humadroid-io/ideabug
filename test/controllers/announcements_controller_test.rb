require "test_helper"

class AnnouncementsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @announcement = create(:announcement)
    @segmented_announcement = create(:announcement, :with_segments)
    @valid_params = {
      announcement: {
        title: "Test Announcement",
        content: "Test Content",
        preview: "Test Preview"
      }
    }
    @invalid_params = {
      announcement: {
        title: "",
        content: "Test Content",
        preview: "Test Preview"
      }
    }
    @user = create(:user)
  end

  context "unauthenticated" do
    should "redirect index to sign-in regardless of public-access config" do
      Rails.application.config.x.announcements_publicly_accessible = true
      get announcements_url
      assert_redirected_to new_session_url
    end

    should "redirect json index to sign-in" do
      get announcements_url(format: :json)
      assert_redirected_to new_session_url
    end

    should "redirect show to sign-in" do
      get announcement_url(@announcement)
      assert_redirected_to new_session_url
    end
  end

  context "authenticated" do
    setup { sign_in_as(@user) }

    context "GET #index" do
      should "render the admin index" do
        get announcements_url
        assert_response :success
        assert_includes @response.body, @announcement.title
        assert_includes @response.body, @segmented_announcement.title
      end

      should "respond with JSON" do
        get announcements_url(format: :json)
        assert_response :success
        assert_equal "application/json", @response.media_type
      end
    end

    context "GET #show" do
      should "render the admin show" do
        get announcement_url(@announcement)
        assert_response :success
      end

      should "respond with JSON" do
        get announcement_url(@announcement, format: :json)
        assert_response :success
        assert_equal "application/json", @response.media_type
      end
    end

    context "GET #new and #edit" do
      should "render new" do
        get new_announcement_url
        assert_response :success
      end

      should "render edit" do
        get edit_announcement_url(@announcement)
        assert_response :success
      end
    end

    context "POST #create" do
      should "create announcement with valid params" do
        assert_difference("Announcement.count") do
          post announcements_url, params: @valid_params
        end
        assert_redirected_to announcement_url(Announcement.last)
        assert_equal "Announcement was successfully created.", flash[:notice]
      end

      should "create announcement via JSON" do
        assert_difference("Announcement.count") do
          post announcements_url, params: @valid_params, as: :json
        end
        assert_response :created
      end

      should "reject invalid params" do
        assert_no_difference("Announcement.count") do
          post announcements_url, params: @invalid_params
        end
        assert_response :unprocessable_entity
      end
    end

    context "PATCH #update" do
      should "update with valid params" do
        patch announcement_url(@announcement), params: {announcement: {title: "Updated Title"}}
        assert_equal "Updated Title", @announcement.reload.title
        assert_redirected_to announcement_url(@announcement)
      end

      should "reject invalid params" do
        patch announcement_url(@announcement), params: {announcement: {title: ""}}
        assert_response :unprocessable_entity
      end
    end

    context "DELETE #destroy" do
      should "destroy announcement" do
        assert_difference("Announcement.count", -1) do
          delete announcement_url(@announcement)
        end
        assert_redirected_to announcements_url
        assert_response :see_other
      end
    end
  end

  teardown do
    Rails.application.config.x.announcements_publicly_accessible = false
  end
end
