# == Schema Information
#
# Table name: tickets
#
#  id             :bigint           not null, primary key
#  classification :integer          default("unclassified")
#  description    :text
#  status         :integer          default("new")
#  title          :string
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
require "test_helper"

class TicketTest < ActiveSupport::TestCase
  setup do
    @ticket = build(:ticket)
  end

  test "should be valid" do
    assert @ticket.valid?
  end

  test "should validate presence of title" do
    @ticket.title = nil
    assert_not @ticket.valid?
    assert_includes @ticket.errors[:title], "can't be blank"
  end

  test "should have default status of new" do
    ticket = create(:ticket)
    assert_equal "new", ticket.status
  end

  test "should have default classification of unclassified" do
    ticket = create(:ticket)
    assert_equal "unclassified", ticket.classification
  end

  test "should define valid status enum values" do
    assert_includes Ticket.statuses.keys, "new"
    assert_includes Ticket.statuses.keys, "in_progress"
    assert_includes Ticket.statuses.keys, "completed"
  end

  test "should define valid classification enum values" do
    assert_includes Ticket.classifications.keys, "unclassified"
    assert_includes Ticket.classifications.keys, "bug"
    assert_includes Ticket.classifications.keys, "feature_request"
    assert_includes Ticket.classifications.keys, "task"
  end

  test "ordered scope should order by created_at desc" do
    old_ticket = create(:ticket, created_at: 2.days.ago)
    new_ticket = create(:ticket, created_at: 1.day.ago)

    assert_equal [new_ticket, old_ticket], Ticket.ordered.to_a
  end

  test "to_s should return ticket title" do
    @ticket.title = "Test Ticket"
    assert_equal "Test Ticket", @ticket.to_s
  end
end
