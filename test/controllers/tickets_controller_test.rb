require "test_helper"

class TicketsControllerTest < ActionDispatch::IntegrationTest
  include FactoryBot::Syntax::Methods

  setup do
    @ticket = create(:ticket)
  end

  test "should get index" do
    get tickets_url
    assert_response :success
  end

  test "should group tickets by status in index" do
    in_progress_ticket = create(:ticket, status: :in_progress)

    get tickets_url
    assert_response :success

    grouped_tickets = assigns(:grouped_tickets)
    assert_equal [@ticket], grouped_tickets["new"]
    assert_equal [in_progress_ticket], grouped_tickets["in_progress"]
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
