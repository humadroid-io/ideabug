require "test_helper"

module Api
  module V1
    class TestController < BaseController
      def test_action
        render json: {message: "success", contact_id: Current.contact.id}
      end

      def test_not_found
        raise ActiveRecord::RecordNotFound
      end

      def test_invalid_record
        record = Contact.new(external_id: nil, anonymous_id: nil)
        record.errors.add(:base, "Test error")
        raise ActiveRecord::RecordInvalid.new(record)
      end
    end

    class BaseControllerTest < ActionDispatch::IntegrationTest
      ANON_HEADER = "X-Ideabug-Anon-Id".freeze

      def setup
        @contact = create(:contact, :identified)
        @token = JwtTestIssuer.generate_token(@contact)

        Rails.application.routes.draw do
          get "test_action" => "api/v1/test#test_action"
          get "test_not_found" => "api/v1/test#test_not_found"
          get "test_invalid_record" => "api/v1/test#test_invalid_record"
        end
      end

      def teardown
        Rails.application.reload_routes!
      end

      test "authenticates with valid JWT and existing contact" do
        get test_action_url, headers: {Authorization: "Bearer #{@token}"}

        assert_response :success
        assert_equal @contact.id, JSON.parse(response.body)["contact_id"]
      end

      test "authenticates by anonymous_id header" do
        anon = create(:contact, :anonymous, anonymous_id: "ib_test_anonymous_id_42")

        get test_action_url, headers: {ANON_HEADER => "ib_test_anonymous_id_42"}

        assert_response :success
        assert_equal anon.id, JSON.parse(response.body)["contact_id"]
      end

      test "creates a new contact when an unknown anonymous_id is presented" do
        assert_difference "Contact.count", 1 do
          get test_action_url, headers: {ANON_HEADER => "ib_brand_new_anon_id_123"}
        end
        assert_response :success
      end

      test "creates a new identified contact when JWT references unknown external_id" do
        new_external_id = "ext-#{SecureRandom.hex(4)}"
        payload = {
          id: new_external_id,
          exp: 1.hour.from_now.to_i,
          iat: Time.current.to_i,
          jti: SecureRandom.uuid
        }
        token = JWT.encode(payload, JwtTestIssuer.private_key, JwtTestIssuer::ALGORITHM)

        assert_difference "Contact.count", 1 do
          get test_action_url, headers: {Authorization: "Bearer #{token}"}
        end
        assert_response :success
      end

      test "updates contact info when present in token" do
        payload = {
          id: @contact.external_id,
          info: {name: "Test User", email: "test@example.com"},
          exp: 1.hour.from_now.to_i,
          iat: Time.current.to_i,
          jti: SecureRandom.uuid
        }
        token = JWT.encode(payload, JwtTestIssuer.private_key, JwtTestIssuer::ALGORITHM)

        get test_action_url, headers: {Authorization: "Bearer #{token}"}

        assert_response :success
        @contact.reload
        assert_equal "Test User", @contact.info_payload["name"]
        assert_equal "test@example.com", @contact.info_payload["email"]
      end

      test "updates contact segments when present in token" do
        segment = create(:segment, identifier: "region", allow_new_values: true)
        existing_value = create(:segment_value, segment: segment, val: "north")

        payload = {
          id: @contact.external_id,
          segments: {region: "north"},
          exp: 1.hour.from_now.to_i,
          iat: Time.current.to_i,
          jti: SecureRandom.uuid
        }
        token = JWT.encode(payload, JwtTestIssuer.private_key, JwtTestIssuer::ALGORITHM)

        get test_action_url, headers: {Authorization: "Bearer #{token}"}

        assert_response :success
        @contact.reload
        assert_equal({"region" => "north"}, @contact.segments_payload)
        assert_includes @contact.segment_values, existing_value
      end

      test "401 when token payload missing id and no anon id" do
        payload = {
          exp: 1.hour.from_now.to_i,
          iat: Time.current.to_i,
          jti: SecureRandom.uuid
        }
        token = JWT.encode(payload, JwtTestIssuer.private_key, JwtTestIssuer::ALGORITHM)

        get test_action_url, headers: {Authorization: "Bearer #{token}"}

        assert_response :unauthorized
        assert_includes JSON.parse(response.body)["error"], "Identity required"
      end

      test "rejects invalid JWT" do
        get test_action_url, headers: {Authorization: "Bearer invalid_token"}

        assert_response :unauthorized
        assert_includes JSON.parse(response.body)["error"], "Invalid"
      end

      test "rejects RS256 token signed with an attacker's private key" do
        attacker_key = OpenSSL::PKey::RSA.new(2048)
        forged = JWT.encode(
          {
            id: @contact.external_id,
            exp: 1.hour.from_now.to_i,
            iat: Time.current.to_i,
            jti: SecureRandom.uuid
          },
          attacker_key,
          JwtTestIssuer::ALGORITHM
        )

        assert_no_difference "Contact.count" do
          get test_action_url, headers: {Authorization: "Bearer #{forged}"}
        end

        assert_response :unauthorized
        assert_includes JSON.parse(response.body)["error"], "verification failed"
      end

      test "rejects HS256 token signed using the public key as HMAC secret (alg confusion)" do
        forged_external_id = "victim-#{SecureRandom.hex(4)}"
        forged = JWT.encode(
          {
            id: forged_external_id,
            exp: 1.hour.from_now.to_i,
            iat: Time.current.to_i,
            jti: SecureRandom.uuid
          },
          JwtConfig.public_key.to_pem,
          "HS256"
        )

        assert_no_difference "Contact.count" do
          get test_action_url, headers: {Authorization: "Bearer #{forged}"}
        end

        assert_response :unauthorized
        assert_nil Contact.find_by(external_id: forged_external_id)
      end

      test "rejects unsigned token with alg=none" do
        forged_external_id = "victim-#{SecureRandom.hex(4)}"
        forged = JWT.encode(
          {
            id: forged_external_id,
            exp: 1.hour.from_now.to_i,
            iat: Time.current.to_i,
            jti: SecureRandom.uuid
          },
          nil,
          "none"
        )

        assert_no_difference "Contact.count" do
          get test_action_url, headers: {Authorization: "Bearer #{forged}"}
        end

        assert_response :unauthorized
        assert_nil Contact.find_by(external_id: forged_external_id)
      end

      test "rejects token whose payload was tampered after signing" do
        victim = create(:contact, :identified, external_id: "victim-#{SecureRandom.hex(4)}")
        victim.update_columns(last_seen_at: 1.day.ago.change(usec: 0))
        victim_seen_at = victim.reload.last_seen_at

        header_b64, _payload_b64, sig_b64 = @token.split(".")
        tampered_payload = Base64.urlsafe_encode64(
          {
            id: victim.external_id,
            exp: 1.hour.from_now.to_i,
            iat: Time.current.to_i,
            jti: SecureRandom.uuid
          }.to_json,
          padding: false
        )
        forged = "#{header_b64}.#{tampered_payload}.#{sig_b64}"

        get test_action_url, headers: {Authorization: "Bearer #{forged}"}

        assert_response :unauthorized
        assert_equal victim_seen_at, victim.reload.last_seen_at
      end

      test "401 when no headers at all" do
        get test_action_url

        assert_response :unauthorized
        assert_includes JSON.parse(response.body)["error"], "Identity required"
      end

      test "rejects expired JWT with descriptive message" do
        travel_to(2.hours.from_now) do
          get test_action_url, headers: {Authorization: "Bearer #{@token}"}

          assert_response :unauthorized
          assert_includes JSON.parse(response.body)["error"], "expired"
        end
      end

      test "rejects malformed anon id" do
        get test_action_url, headers: {ANON_HEADER => "no spaces allowed"}
        assert_response :unauthorized
      end

      test "RecordNotFound returns 404 envelope" do
        get test_not_found_url, headers: {Authorization: "Bearer #{@token}"}

        assert_response :not_found
        assert_equal "404", JSON.parse(response.body)["errors"].first["status"]
      end

      test "RecordInvalid returns 422 envelope" do
        get test_invalid_record_url, headers: {Authorization: "Bearer #{@token}"}

        assert_response :unprocessable_entity
        assert_equal "422", JSON.parse(response.body)["errors"].first["status"]
      end

      test "surfaces opt-out and contact id headers" do
        get test_action_url, headers: {Authorization: "Bearer #{@token}"}

        assert_response :success
        assert_equal @contact.id.to_s, response.headers["X-Ideabug-Contact-Id"]
        assert_equal "", response.headers["X-Ideabug-Anonymous-Id"]
        assert_equal "false", response.headers["X-Ideabug-Opted-Out"]
      end

      test "merges anonymous contact when JWT and anon header both present" do
        anon = create(:contact, :anonymous)
        announcement = create(:announcement)
        create(:announcement_read, announcement: announcement, contact: anon)

        get test_action_url, headers: {
          :Authorization => "Bearer #{@token}",
          ANON_HEADER => anon.anonymous_id
        }

        assert_response :success
        assert_nil Contact.find_by(id: anon.id)
        assert_equal 1, AnnouncementRead.where(contact_id: @contact.id).count
        assert_equal @contact.id, JSON.parse(response.body)["contact_id"]
        assert_equal "", response.headers["X-Ideabug-Anonymous-Id"]
      end
    end
  end
end
