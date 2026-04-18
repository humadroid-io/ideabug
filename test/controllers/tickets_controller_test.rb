require "test_helper"

class TicketsControllerTest < ActionDispatch::IntegrationTest
  include FactoryBot::Syntax::Methods

  setup do
    @ticket = create(:ticket)
    @user = create(:user)  # Assuming you have a user factory
    sign_in_as(@user)
  end

  test "should redirect to sign in when not authenticated" do
    sign_out
    get tickets_url
    assert_redirected_to new_session_url
  end

  test "should get index" do
    get tickets_url
    assert_response :success
  end

  test "should filter index by classification + status + search query" do
    bug = create(:ticket, :bug, title: "DB exception")
    feature = create(:ticket, :feature, title: "Add dark mode")
    create(:ticket, status: :completed, classification: :task, title: "Cleanup logs")

    get tickets_url(classification: "bug")
    assert_includes assigns(:tickets).map(&:id), bug.id
    refute_includes assigns(:tickets).map(&:id), feature.id

    get tickets_url(status: "completed")
    titles = assigns(:tickets).map(&:title)
    assert_includes titles, "Cleanup logs"

    get tickets_url(q: "dark")
    assert_equal [feature.id], assigns(:tickets).map(&:id)
  end

  test "should sort by votes when requested" do
    a = create(:ticket, :feature)
    b = create(:ticket, :feature)
    create(:ticket_vote, ticket: b)

    get tickets_url(sort: "votes", classification: "feature_request")
    ids = assigns(:tickets).map(&:id)
    assert_equal b.id, ids.first
    assert_includes ids, a.id
  end

  test "should render the timeline action" do
    create(:ticket, :feature, status: :in_progress, title: "In flight")
    create(:ticket, :feature, scheduled_for: 1.week.from_now, title: "Coming soon")
    create(:ticket, :feature, shipped_at: 1.day.ago, status: :completed, title: "Done")

    get timeline_tickets_url
    assert_response :success
    assert_match "In flight", response.body
    assert_match "Coming soon", response.body
    assert_match "Done", response.body
  end

  test "should get new" do
    get new_ticket_url
    assert_response :success
  end

  test "should create ticket" do
    assert_difference("Ticket.count") do
      post tickets_url, params: {
        ticket: {
          title: "New Ticket",
          description: "Test Description",
          status: "new",
          classification: "unclassified"
        }
      }
    end

    assert_redirected_to ticket_url(Ticket.last)
  end

  test "should not create ticket with invalid params" do
    assert_no_difference("Ticket.count") do
      post tickets_url, params: {
        ticket: {
          title: "",
          description: "Test Description"
        }
      }
    end

    assert_response :unprocessable_entity
  end

  test "should show ticket" do
    get ticket_url(@ticket)
    assert_response :success
  end

  test "should get edit" do
    get edit_ticket_url(@ticket)
    assert_response :success
  end

  test "should update ticket" do
    patch ticket_url(@ticket), params: {
      ticket: {
        title: "Updated Title",
        description: @ticket.description
      }
    }
    assert_redirected_to ticket_url(@ticket)
    @ticket.reload
    assert_equal "Updated Title", @ticket.title
  end

  test "should not update ticket with invalid params" do
    patch ticket_url(@ticket), params: {
      ticket: {
        title: "",
        description: @ticket.description
      }
    }
    assert_response :unprocessable_entity
  end

  test "should destroy ticket" do
    assert_difference("Ticket.count", -1) do
      delete ticket_url(@ticket)
    end

    assert_redirected_to tickets_url
  end
end
