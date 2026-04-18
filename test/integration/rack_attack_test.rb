require "test_helper"

class RackAttackTest < ActionDispatch::IntegrationTest
  ANON_HEADER = "X-Ideabug-Anon-Id".freeze

  setup do
    Rack::Attack.cache.store.clear
    Rack::Attack.enabled = true
  end

  teardown do
    Rack::Attack.cache.store.clear
  end

  test "throttles ticket creation per anon id after 5 requests in 10 minutes" do
    contact = create(:contact, :anonymous, anonymous_id: "ib_throttle_test_anon_42")
    headers = {ANON_HEADER => contact.anonymous_id}
    payload = {ticket: {title: "feature x", classification: "feature_request"}}

    5.times do |i|
      post api_v1_tickets_url, headers: headers, params: payload, as: :json
      assert_response :created, "request #{i + 1}/5 should succeed"
    end

    post api_v1_tickets_url, headers: headers, params: payload, as: :json
    assert_response :too_many_requests
  end
end
