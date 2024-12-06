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
end
