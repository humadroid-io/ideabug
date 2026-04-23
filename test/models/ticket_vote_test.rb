# == Schema Information
#
# Table name: ticket_votes
#
#  id         :bigint           not null, primary key
#  voted_at   :datetime         not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  contact_id :bigint           not null
#  ticket_id  :bigint           not null
#
# Indexes
#
#  index_ticket_votes_on_contact_id                (contact_id)
#  index_ticket_votes_on_ticket_id                 (ticket_id)
#  index_ticket_votes_on_ticket_id_and_contact_id  (ticket_id,contact_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (contact_id => contacts.id) ON DELETE => cascade
#  fk_rails_...  (ticket_id => tickets.id) ON DELETE => cascade
#
require "test_helper"

class TicketVoteTest < ActiveSupport::TestCase
  context "factory" do
    should "be valid" do
      assert build(:ticket_vote).valid?
    end
  end

  context "validations" do
    should "enforce one vote per (ticket, contact)" do
      vote = create(:ticket_vote)
      duplicate = build(:ticket_vote, ticket: vote.ticket, contact: vote.contact)
      refute duplicate.valid?
    end

    should "default voted_at to now if blank" do
      vote = create(:ticket_vote, voted_at: nil)
      assert_not_nil vote.voted_at
    end
  end

  context "counter cache" do
    should "increment tickets.votes_count on create and decrement on destroy" do
      ticket = create(:ticket, :feature)
      assert_equal 0, ticket.votes_count

      vote = create(:ticket_vote, ticket: ticket)
      assert_equal 1, ticket.reload.votes_count

      vote.destroy!
      assert_equal 0, ticket.reload.votes_count
    end
  end
end
