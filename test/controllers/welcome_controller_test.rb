require "test_helper"

class WelcomeControllerTest < ActionDispatch::IntegrationTest
  teardown { Rails.application.config.x.announcements_publicly_accessible = false }

  test "renders the marketing home when public access is disabled and visitor is anonymous" do
    Rails.application.config.x.announcements_publicly_accessible = false
    get root_url
    assert_response :success
    assert_select "h1", text: /Feedback that stays close to your product/
    assert_select "html[data-theme='ideabug']"
    assert_select "body.public-shell[data-controller~='theme']"
    assert_select "button[data-action='theme#toggle'][aria-label='Switch to dark mode']"
  end

  test "redirects anonymous visitors to /changelog when public access is enabled" do
    Rails.application.config.x.announcements_publicly_accessible = true
    get root_url
    assert_redirected_to public_announcements_path
  end

  test "redirects authenticated admins to /dashboard" do
    user = create(:user)
    sign_in_as(user)
    get root_url
    assert_redirected_to dashboard_path
  end
end
