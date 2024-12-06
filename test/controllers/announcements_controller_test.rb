require "test_helper"

class AnnouncementsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @announcement = create(:announcement)
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
    @user = create(:user)  # Assuming you have a user factory
    sign_in_as(@user)
  end

  test "should redirect to sign in when not authenticated" do
    sign_out
    get announcements_url
    assert_redirected_to new_session_url
  end

  test "should not get list of announcements when calling json" do
    sign_out
    get announcements_url(format: :json)
    assert_redirected_to new_session_url
  end

  context "GET #index" do
    should "get index" do
      get announcements_url
      assert_response :success
    end

    should "get index in JSON format" do
      get announcements_url(format: :json)
      assert_response :success
      assert_equal "application/json", @response.media_type
    end
  end

  context "GET #show" do
    should "show announcement" do
      get announcement_url(@announcement)
      assert_response :success
    end

    should "show announcement in JSON format" do
      get announcement_url(@announcement, format: :json)
      assert_response :success
      assert_equal "application/json", @response.media_type
    end
  end

  context "GET #new" do
    should "get new" do
      get new_announcement_url
      assert_response :success
    end
  end

  context "GET #edit" do
    should "get edit" do
      get edit_announcement_url(@announcement)
      assert_response :success
    end
  end

  context "POST #create" do
    context "with valid params" do
      should "create announcement" do
        assert_difference("Announcement.count") do
          post announcements_url, params: @valid_params
        end

        assert_redirected_to announcement_url(Announcement.last)
        assert_equal "Announcement was successfully created.", flash[:notice]
      end

      should "create announcement in JSON format" do
        assert_difference("Announcement.count") do
          post announcements_url,
            params: @valid_params,
            as: :json
        end

        assert_response :created
        assert_equal "application/json", @response.media_type
      end
    end

    context "with invalid params" do
      should "not create announcement" do
        assert_no_difference("Announcement.count") do
          post announcements_url, params: @invalid_params
        end

        assert_response :unprocessable_entity
      end

      should "return errors in JSON format" do
        post announcements_url,
          params: @invalid_params,
          as: :json

        assert_response :unprocessable_entity
        assert_equal "application/json", @response.media_type
      end
    end
  end

  context "PATCH #update" do
    context "with valid params" do
      should "update announcement" do
        patch announcement_url(@announcement),
          params: {announcement: {title: "Updated Title"}}

        @announcement.reload
        assert_equal "Updated Title", @announcement.title
        assert_redirected_to announcement_url(@announcement)
        assert_equal "Announcement was successfully updated.", flash[:notice]
      end

      should "update announcement in JSON format" do
        patch announcement_url(@announcement),
          params: {announcement: {title: "Updated Title"}},
          as: :json

        assert_response :ok
        assert_equal "application/json", @response.media_type
      end
    end

    context "with invalid params" do
      should "not update announcement" do
        patch announcement_url(@announcement),
          params: {announcement: {title: ""}}

        assert_response :unprocessable_entity
      end

      should "return errors in JSON format" do
        patch announcement_url(@announcement),
          params: {announcement: {title: ""}},
          as: :json

        assert_response :unprocessable_entity
        assert_equal "application/json", @response.media_type
      end
    end
  end

  context "DELETE #destroy" do
    should "destroy announcement" do
      assert_difference("Announcement.count", -1) do
        delete announcement_url(@announcement)
      end

      assert_redirected_to announcements_url
      assert_equal "Announcement was successfully destroyed.", flash[:notice]
      assert_response :see_other
    end

    should "destroy announcement in JSON format" do
      assert_difference("Announcement.count", -1) do
        delete announcement_url(@announcement), as: :json
      end

      assert_response :no_content
    end
  end
end
