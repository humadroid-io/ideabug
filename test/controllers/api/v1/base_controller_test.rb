require "test_helper"

module Api
  module V1
    class TestController < BaseController
      def test_action
        render json: {message: "success", contact_id: @current_contact.id}
      end

      def test_not_found
        raise ActiveRecord::RecordNotFound
      end

      def test_invalid_record
        record = Contact.new
        record.errors.add(:base, "Test error")
        raise ActiveRecord::RecordInvalid.new(record)
      end
    end

    class BaseControllerTest < ActionDispatch::IntegrationTest
      def setup
        @contact = create(:contact)
        @token = JwtCredentialService.generate_token(@contact)

        Rails.application.routes.draw do
          get "test_action" => "api/v1/test#test_action"
          get "test_not_found" => "api/v1/test#test_not_found"
          get "test_invalid_record" => "api/v1/test#test_invalid_record"
        end
      end

      def teardown
        Rails.application.reload_routes!
      end

      test "should authenticate with valid token and existing contact" do
        get test_action_url,
          headers: {Authorization: "Bearer #{@token}"}

        assert_response :success
        json_response = JSON.parse(response.body)
        assert_equal "success", json_response["message"]
        assert_equal @contact.id, json_response["contact_id"]
      end

      test "should create new contact if not exists" do
        # Generate token with non-existent contact ID
        new_contact_id = Contact.maximum(:id).to_i + 1
        payload = {
          id: new_contact_id,
          exp: 1.hour.from_now.to_i,
          iat: Time.current.to_i,
          jti: SecureRandom.uuid
        }
        token = JWT.encode(payload, JwtConfig.private_key, JwtCredentialService::ALGORITHM)

        assert_difference "Contact.count", 1 do
          get test_action_url,
            headers: {Authorization: "Bearer #{token}"}
        end

        assert_response :success
        json_response = JSON.parse(response.body)
        assert_equal new_contact_id, json_response["contact_id"]
      end

      test "should update contact info when present in token" do
        payload = {
          id: @contact.external_id,
          info: {name: "Test User", email: "test@example.com"},
          exp: 1.hour.from_now.to_i,
          iat: Time.current.to_i,
          jti: SecureRandom.uuid
        }
        token = JWT.encode(payload, JwtConfig.private_key, JwtCredentialService::ALGORITHM)

        get test_action_url,
          headers: {Authorization: "Bearer #{token}"}

        assert_response :success
        @contact.reload
        assert_equal "Test User", @contact.info_payload["name"]
        assert_equal "test@example.com", @contact.info_payload["email"]
      end

      test "should fail when token payload missing id" do
        payload = {
          exp: 1.hour.from_now.to_i,
          iat: Time.current.to_i,
          jti: SecureRandom.uuid
        }
        token = JWT.encode(payload, JwtConfig.private_key, JwtCredentialService::ALGORITHM)

        get test_action_url,
          headers: {Authorization: "Bearer #{token}"}

        assert_response :unauthorized
        json_response = JSON.parse(response.body)
        assert_includes json_response["error"], "Authentication failed"
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

      test "should handle expired token" do
        travel_to(2.hours.from_now) do
          get test_action_url,
            headers: {Authorization: "Bearer #{@token}"}

          assert_response :unauthorized
          json_response = JSON.parse(response.body)
          assert_includes json_response["error"], "expired"
        end
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
