# == Schema Information
#
# Table name: tickets
#
#  id                :bigint           not null, primary key
#  classification    :integer          default("unclassified")
#  context           :jsonb
#  description       :text
#  public_on_roadmap :boolean          default(FALSE), not null
#  scheduled_for     :datetime
#  shipped_at        :datetime
#  source            :string           default("admin"), not null
#  status            :integer          default("new")
#  title             :string
#  votes_count       :integer          default(0), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  contact_id        :bigint
#
# Indexes
#
#  index_tickets_on_classification_and_status             (classification,status)
#  index_tickets_on_contact_id                            (contact_id)
#  index_tickets_on_public_on_roadmap_and_classification  (public_on_roadmap,classification)
#  index_tickets_on_scheduled_for                         (scheduled_for)
#  index_tickets_on_shipped_at                            (shipped_at)
#  index_tickets_on_source                                (source)
#
# Foreign Keys
#
#  fk_rails_...  (contact_id => contacts.id)
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

  test "should validate inclusion of source" do
    @ticket.source = "bogus"
    refute @ticket.valid?
  end

  test "should have default status of new" do
    ticket = create(:ticket)
    assert_equal "new", ticket.status
  end

  test "should have default classification of unclassified" do
    ticket = create(:ticket)
    assert_equal "unclassified", ticket.classification
  end

  test "should default to admin source" do
    assert_equal "admin", create(:ticket).source
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

  context "roadmap scopes" do
    setup do
      @feature = create(:ticket, :feature)
      @bug = create(:ticket, :bug)
      @scheduled = create(:ticket, :feature, :scheduled)
      @shipped = create(:ticket, :feature, :shipped)
    end

    should "filter on_roadmap" do
      assert_includes Ticket.on_roadmap, @feature
      refute_includes Ticket.on_roadmap, @bug
    end

    should "filter scheduled (not shipped)" do
      assert_includes Ticket.scheduled, @scheduled
      refute_includes Ticket.scheduled, @shipped
      refute_includes Ticket.scheduled, @feature
    end

    should "filter shipped" do
      assert_includes Ticket.shipped, @shipped
      refute_includes Ticket.shipped, @scheduled
    end

    should "filter bugs and features" do
      assert_includes Ticket.bugs, @bug
      refute_includes Ticket.bugs, @feature

      assert_includes Ticket.features, @feature
      refute_includes Ticket.features, @bug
    end
  end

  test "to_s should return ticket title" do
    @ticket.title = "Test Ticket"
    assert_equal "Test Ticket", @ticket.to_s
  end
end
