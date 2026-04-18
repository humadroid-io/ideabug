require "test_helper"

module Api
  module V1
    class IdentityControllerTest < ActionDispatch::IntegrationTest
      ANON_HEADER = "X-Ideabug-Anon-Id".freeze

      test "mints a fresh anonymous contact when no headers provided" do
        assert_difference "Contact.count", 1 do
          post api_v1_identity_url
        end

        assert_response :success
        body = JSON.parse(response.body)
        refute body["identified"]
        assert_match(/\Aib_[A-Za-z0-9]{22}\z/, body["anonymous_id"])
        assert_equal false, body["opted_out"]
        assert_equal 0, body["unread_count"]
        assert_equal body["anonymous_id"], Contact.last.anonymous_id
      end

      test "identity returns unread_count so the widget can render the bell without a list fetch" do
        create_list(:announcement, 4, published_at: 1.day.ago)

        post api_v1_identity_url
        body = JSON.parse(response.body)
        assert_equal 4, body["unread_count"]
        assert_equal "4", response.headers["X-Ideabug-Unread"]
      end

      test "echoes existing anonymous contact" do
        contact = create(:contact, :anonymous)

        assert_no_difference "Contact.count" do
          post api_v1_identity_url, headers: {ANON_HEADER => contact.anonymous_id}
        end

        body = JSON.parse(response.body)
        assert_equal contact.anonymous_id, body["anonymous_id"]
        assert_equal contact.id, body["contact_id"]
      end

      test "creates an unknown anonymous_id sent by client" do
        assert_difference "Contact.count", 1 do
          post api_v1_identity_url, headers: {ANON_HEADER => "ib_client_supplied_value_xyz"}
        end

        body = JSON.parse(response.body)
        assert_equal "ib_client_supplied_value_xyz", body["anonymous_id"]
      end

      test "with JWT only, returns identified contact" do
        contact = create(:contact, :identified)
        token = JwtCredentialService.generate_token(contact)

        post api_v1_identity_url, headers: {Authorization: "Bearer #{token}"}

        body = JSON.parse(response.body)
        assert body["identified"]
        assert_equal contact.id, body["contact_id"]
        assert_equal contact.external_id, body["external_id"]
      end

      test "with both anon and JWT, merges anon into identified" do
        anon = create(:contact, :anonymous)
        ident = create(:contact, :identified)
        announcement = create(:announcement)
        ticket = create(:ticket, :feature)
        create(:announcement_read, announcement: announcement, contact: anon)
        create(:ticket_vote, ticket: ticket, contact: anon)

        token = JwtCredentialService.generate_token(ident)

        post api_v1_identity_url, headers: {
          :Authorization => "Bearer #{token}",
          ANON_HEADER => anon.anonymous_id
        }

        assert_response :success
        body = JSON.parse(response.body)
        assert body["identified"]
        assert_equal ident.id, body["contact_id"]
        assert_nil Contact.find_by(id: anon.id)
        assert_equal 1, AnnouncementRead.where(contact_id: ident.id).count
        assert_equal 1, TicketVote.where(contact_id: ident.id).count
      end

      test "ignores malformed anonymous_id and mints a fresh one" do
        assert_difference "Contact.count", 1 do
          post api_v1_identity_url, headers: {ANON_HEADER => "has spaces"}
        end
        body = JSON.parse(response.body)
        assert_match(/\Aib_/, body["anonymous_id"])
      end
    end
  end
end
