require "test_helper"

module Api
  module V1
    class TestController < BaseController
      def test_action
        render json: {message: "success"}
      end

      def test_not_found
        raise ActiveRecord::RecordNotFound
      end

      def test_invalid_record
        record = User.new
        record.errors.add(:base, "Test error")
        raise ActiveRecord::RecordInvalid.new(record)
      end
    end

    class BaseControllerTest < ActionDispatch::IntegrationTest
      def setup
        @user = create(:user)
        @token = JwtCredentialService.generate_token(@user)

        Rails.application.routes.draw do
          get "test_action" => "api/v1/test#test_action"
          get "test_not_found" => "api/v1/test#test_not_found"
          get "test_invalid_record" => "api/v1/test#test_invalid_record"
        end
      end

      def teardown
        Rails.application.reload_routes!
      end

      test "should authenticate with valid token" do
        get test_action_url,
          headers: {Authorization: "Bearer #{@token}"}

        assert_response :success
        json_response = JSON.parse(response.body)
        assert_equal "success", json_response["message"]
      end

      test "should reject invalid token" do
        get test_action_url,
          headers: {Authorization: "Bearer invalid_token"}

        assert_response :unauthorized
        json_response = JSON.parse(response.body)
        assert_includes json_response["error"], "Invalid token"
      end

      test "should handle missing token" do
        get test_action_url

        assert_response :unauthorized
        json_response = JSON.parse(response.body)
        assert_includes json_response["error"], "Invalid token"
      end

      test "should handle record not found error" do
        get test_not_found_url,
          headers: {Authorization: "Bearer #{@token}"}

        assert_response :not_found
        json_response = JSON.parse(response.body)
        assert_equal "404", json_response["errors"].first["status"]
      end

      test "should handle invalid record error" do
        get test_invalid_record_url,
          headers: {Authorization: "Bearer #{@token}"}

        assert_response :unprocessable_entity
        json_response = JSON.parse(response.body)
        assert_equal "422", json_response["errors"].first["status"]
      end
    end
  end
end
