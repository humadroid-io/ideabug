require "test_helper"

class ContactMergeServiceTest < ActiveSupport::TestCase
  setup do
    @anon = create(:contact, :anonymous)
    @ident = create(:contact, :identified)
    @announcement_a = create(:announcement)
    @announcement_b = create(:announcement)
    @ticket_a = create(:ticket, :feature)
    @ticket_b = create(:ticket, :feature)
  end

  context "when anonymous contact is nil" do
    should "be a no-op returning the identified contact" do
      result = ContactMergeService.call(anonymous: nil, identified: @ident)

      assert_equal @ident, result.contact
      refute result.merged
      assert_equal 0, result.collapsed_reads
      assert_equal 0, result.collapsed_votes
    end
  end

  context "when anonymous and identified are the same" do
    should "be a no-op" do
      result = ContactMergeService.call(anonymous: @ident, identified: @ident)
      refute result.merged
    end
  end

  context "when anonymous has reads and votes that the identified does not" do
    should "re-point reads, votes, and submitted tickets and destroy the anon row" do
      create(:announcement_read, announcement: @announcement_a, contact: @anon)
      create(:ticket_vote, ticket: @ticket_a, contact: @anon)
      submitted = create(:ticket, :bug, contact: @anon, source: "widget")

      result = ContactMergeService.call(anonymous: @anon, identified: @ident)

      assert result.merged
      assert_equal 0, result.collapsed_reads
      assert_equal 0, result.collapsed_votes
      assert_nil Contact.find_by(id: @anon.id)

      assert_equal 1, AnnouncementRead.where(contact_id: @ident.id).count
      assert_equal 1, TicketVote.where(contact_id: @ident.id).count
      assert_equal @ident.id, submitted.reload.contact_id
      assert_equal 1, @ticket_a.reload.votes_count
    end
  end

  context "when both contacts have read the same announcement and voted the same ticket" do
    should "collapse duplicates and keep the identified contact's rows" do
      create(:announcement_read, announcement: @announcement_a, contact: @anon)
      create(:announcement_read, announcement: @announcement_a, contact: @ident)
      create(:announcement_read, announcement: @announcement_b, contact: @anon)

      create(:ticket_vote, ticket: @ticket_a, contact: @anon)
      create(:ticket_vote, ticket: @ticket_a, contact: @ident)
      create(:ticket_vote, ticket: @ticket_b, contact: @anon)

      result = ContactMergeService.call(anonymous: @anon, identified: @ident)

      assert result.merged
      assert_equal 1, result.collapsed_reads
      assert_equal 1, result.collapsed_votes

      reads = AnnouncementRead.where(contact_id: @ident.id).pluck(:announcement_id).sort
      assert_equal [@announcement_a.id, @announcement_b.id].sort, reads

      votes = TicketVote.where(contact_id: @ident.id).pluck(:ticket_id).sort
      assert_equal [@ticket_a.id, @ticket_b.id].sort, votes

      assert_equal 1, @ticket_a.reload.votes_count
      assert_equal 1, @ticket_b.reload.votes_count
    end
  end
end
