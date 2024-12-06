require "test_helper"

class WelcomeControllerTest < ActionDispatch::IntegrationTest
  test "should get home" do
    get root_url
    assert_response :redirect
  end
end
