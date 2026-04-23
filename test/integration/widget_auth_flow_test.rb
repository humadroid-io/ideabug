require "test_helper"

class WidgetAuthFlowTest < ActionDispatch::IntegrationTest
  ANON_HEADER = "X-Ideabug-Anon-Id".freeze

  test "anonymous reads + votes carry over when caller upgrades to JWT" do
    # 1) Bootstrap: mint anon
    post api_v1_identity_url
    assert_response :success
    anon_id = JSON.parse(response.body)["anonymous_id"]
    assert_match(/\Aib_/, anon_id)

    # 2) As anon: read an announcement and vote on a feature
    announcement = create(:announcement, published_at: Time.current)
    feature = create(:ticket, :feature)

    post read_api_v1_announcement_url(announcement), headers: {ANON_HEADER => anon_id}
    assert_response :success

    post vote_api_v1_ticket_url(feature), headers: {ANON_HEADER => anon_id}
    assert_response :success
    assert_equal 1, feature.reload.votes_count

    anon_contact = Contact.find_by(anonymous_id: anon_id)
    assert anon_contact
    assert_equal 1, AnnouncementRead.where(contact_id: anon_contact.id).count
    assert_equal 1, TicketVote.where(contact_id: anon_contact.id).count

    # 3) Upgrade: same browser sends JWT alongside the anon id
    identified = create(:contact, :identified)
    token = JwtCredentialService.generate_token(identified)

    post api_v1_identity_url, headers: {
      :Authorization => "Bearer #{token}",
      ANON_HEADER => anon_id
    }
    assert_response :success
    body = JSON.parse(response.body)
    assert body["identified"]
    assert_equal identified.id, body["contact_id"]

    # 4) Anon row gone; reads + votes re-pointed; counter cache intact
    assert_nil Contact.find_by(id: anon_contact.id)
    assert_equal 1, AnnouncementRead.where(contact_id: identified.id).count
    assert_equal 1, TicketVote.where(contact_id: identified.id).count
    assert_equal 1, feature.reload.votes_count
  end
end
