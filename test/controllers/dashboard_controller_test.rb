require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)  # Assuming you have a user factory
    sign_in_as(@user)
  end

  test "should get index" do
    get dashboard_url
    assert_response :success
  end

  test "renders stats with non-trivial data" do
    Rails.cache.clear
    create(:contact, :anonymous)
    create(:contact, :identified)
    create(:announcement, published_at: 2.days.ago)
    create(:ticket, :feature)
    feature = create(:ticket, :feature, title: "Most Wanted")
    create(:ticket_vote, ticket: feature)
    create(:ticket, :bug, title: "Recent Bug")

    get dashboard_url
    assert_response :success
    assert_match "Most Wanted", response.body
    assert_match "Recent Bug", response.body
  end
end
