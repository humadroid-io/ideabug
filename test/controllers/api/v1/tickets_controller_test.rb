require "test_helper"

module Api
  module V1
    class TicketsControllerTest < ActionDispatch::IntegrationTest
      ANON_HEADER = "X-Ideabug-Anon-Id".freeze

      def setup
        @contact = create(:contact, :anonymous, anonymous_id: "ib_test_contact_for_tickets")
        @headers = {ANON_HEADER => @contact.anonymous_id}
      end

      context "GET index" do
        should "return public roadmap features sorted by votes desc by default" do
          a = create(:ticket, :feature, title: "Less voted")
          b = create(:ticket, :feature, title: "More voted")
          create(:ticket_vote, ticket: b)
          create(:ticket_vote, ticket: b, contact: create(:contact, :anonymous))
          create(:ticket_vote, ticket: a)

          get api_v1_tickets_url, headers: @headers

          assert_response :success
          body = JSON.parse(response.body)
          assert_equal [b.id, a.id], body.map { |t| t["id"] }
        end

        should "exclude non-public tickets" do
          create(:ticket, :feature, public_on_roadmap: false, title: "private")
          create(:ticket, :feature, title: "public")

          get api_v1_tickets_url, headers: @headers

          assert_response :success
          titles = JSON.parse(response.body).map { |t| t["title"] }
          assert_includes titles, "public"
          refute_includes titles, "private"
        end

        should "annotate voted_by_me" do
          ticket = create(:ticket, :feature)
          create(:ticket_vote, ticket: ticket, contact: @contact)

          get api_v1_tickets_url, headers: @headers

          assert_response :success
          body = JSON.parse(response.body)
          assert body.first["voted_by_me"]
        end
      end

      context "GET show" do
        should "404 a private ticket the caller did not author" do
          ticket = create(:ticket, :bug, public_on_roadmap: false)

          get api_v1_ticket_url(ticket), headers: @headers
          assert_response :not_found
        end

        should "return a private ticket the caller authored" do
          ticket = create(:ticket, :bug, public_on_roadmap: false, contact: @contact)

          get api_v1_ticket_url(ticket), headers: @headers
          assert_response :success
          assert_equal ticket.id, JSON.parse(response.body)["id"]
        end
      end

      context "POST create" do
        should "create a feature request marked widget+public" do
          assert_difference "Ticket.count", 1 do
            post api_v1_tickets_url,
              headers: @headers,
              params: {ticket: {title: "Add dark mode", classification: "feature_request"}},
              as: :json
          end

          ticket = Ticket.last
          assert_equal @contact.id, ticket.contact_id
          assert_equal "widget", ticket.source
          assert ticket.public_on_roadmap
          assert_equal "feature_request", ticket.classification
        end

        should "create a bug ticket as private" do
          post api_v1_tickets_url,
            headers: @headers,
            params: {ticket: {title: "Crash on click", classification: "bug",
                              context: {url: "/foo", user_agent: "X"}}},
            as: :json

          assert_response :created
          ticket = Ticket.last
          refute ticket.public_on_roadmap
          assert_equal "bug", ticket.classification
          assert_equal({"url" => "/foo", "user_agent" => "X"}, ticket.context)
        end
      end

      context "POST vote" do
        should "create a vote on a public feature and bump the count" do
          ticket = create(:ticket, :feature)

          assert_difference "TicketVote.count", 1 do
            post vote_api_v1_ticket_url(ticket), headers: @headers
          end

          assert_response :success
          body = JSON.parse(response.body)
          assert body["voted_by_me"]
          assert_equal 1, body["votes_count"]
          assert_equal 1, ticket.reload.votes_count
        end

        should "be idempotent" do
          ticket = create(:ticket, :feature)
          create(:ticket_vote, ticket: ticket, contact: @contact)

          assert_no_difference "TicketVote.count" do
            post vote_api_v1_ticket_url(ticket), headers: @headers
          end
          assert_response :success
        end

        should "reject voting on a bug" do
          ticket = create(:ticket, :bug, public_on_roadmap: true)

          post vote_api_v1_ticket_url(ticket), headers: @headers
          assert_response :unprocessable_entity
        end

        should "reject voting on a private feature" do
          ticket = create(:ticket, :feature, public_on_roadmap: false)
          post vote_api_v1_ticket_url(ticket), headers: @headers
          # private ticket → not visible → 404
          assert_response :not_found
        end
      end

      context "DELETE vote" do
        should "remove the caller's vote" do
          ticket = create(:ticket, :feature)
          create(:ticket_vote, ticket: ticket, contact: @contact)

          assert_difference "TicketVote.count", -1 do
            delete vote_api_v1_ticket_url(ticket), headers: @headers
          end

          assert_response :success
          body = JSON.parse(response.body)
          refute body["voted_by_me"]
          assert_equal 0, body["votes_count"]
        end
      end
    end
  end
end
