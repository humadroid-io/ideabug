require "test_helper"

class PublicAnnouncementsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @broadcast = create(:announcement, title: "Hello world", published_at: 1.day.ago)
    @future = create(:announcement, title: "Coming soon", published_at: 1.week.from_now)
    @segmented = create(:announcement, :with_segments, title: "Internal beta")
  end

  teardown { Rails.application.config.x.announcements_publicly_accessible = false }

  context "when public access is disabled" do
    setup { Rails.application.config.x.announcements_publicly_accessible = false }

    should "404 the index" do
      get public_announcements_url
      assert_response :not_found
    end

    should "404 the show" do
      get public_announcement_url(@broadcast)
      assert_response :not_found
    end
  end

  context "when public access is enabled" do
    setup { Rails.application.config.x.announcements_publicly_accessible = true }

    should "render only published broadcast announcements on index" do
      get public_announcements_url
      assert_response :success
      assert_includes @response.body, @broadcast.title
      refute_includes @response.body, @future.title
      refute_includes @response.body, @segmented.title
    end

    should "render a published broadcast announcement on show" do
      get public_announcement_url(@broadcast)
      assert_response :success
      assert_includes @response.body, @broadcast.title
    end

    should "404 a future-dated announcement on show" do
      assert_raises(ActiveRecord::RecordNotFound) do
        get public_announcement_url(@future)
      end
    end

    should "404 a segmented announcement on show" do
      assert_raises(ActiveRecord::RecordNotFound) do
        get public_announcement_url(@segmented)
      end
    end

    should "render the public layout (no admin chrome)" do
      get public_announcements_url
      refute_includes @response.body, "Dashboard"
      assert_includes @response.body, "humadroid.io"
    end

    should "expose nav links to roadmap, changelog, and admin sign-in" do
      get public_announcements_url
      assert_select "header nav a[href=?]", new_session_path, text: /Sign in/
      assert_select "header nav a[href=?]", "/roadmap", text: /Roadmap/
      assert_select "header nav a[href=?]", public_announcements_path, text: /Changelog/
    end
  end
end
