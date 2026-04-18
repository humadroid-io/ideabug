# frozen_string_literal: true

class ContactMergeService
  Result = Struct.new(:contact, :merged, :collapsed_reads, :collapsed_votes, keyword_init: true)

  def initialize(anonymous:, identified:)
    @anonymous = anonymous
    @identified = identified
  end

  def self.call(...)
    new(...).call
  end

  def call
    return Result.new(contact: @identified, merged: false, collapsed_reads: 0, collapsed_votes: 0) if @anonymous.nil? || @anonymous == @identified

    Contact.transaction do
      collapsed_reads = repoint_reads
      affected_ticket_ids = TicketVote.where(contact_id: @anonymous.id).pluck(:ticket_id).uniq
      collapsed_votes = repoint_votes
      Ticket.where(contact_id: @anonymous.id).update_all(contact_id: @identified.id)

      @anonymous.destroy!
      affected_ticket_ids.each { |tid| Ticket.reset_counters(tid, :ticket_votes) }

      log_collapse(collapsed_reads, collapsed_votes)
      Result.new(contact: @identified.reload, merged: true,
        collapsed_reads: collapsed_reads, collapsed_votes: collapsed_votes)
    end
  end

  private

  def repoint_reads
    keep_announcement_ids = AnnouncementRead.where(contact_id: @identified.id).pluck(:announcement_id)
    duplicates = AnnouncementRead.where(contact_id: @anonymous.id, announcement_id: keep_announcement_ids)
    collapsed = duplicates.count
    duplicates.delete_all
    AnnouncementRead.where(contact_id: @anonymous.id).update_all(contact_id: @identified.id)
    collapsed
  end

  def repoint_votes
    keep_ticket_ids = TicketVote.where(contact_id: @identified.id).pluck(:ticket_id)
    duplicates = TicketVote.where(contact_id: @anonymous.id, ticket_id: keep_ticket_ids)
    collapsed = duplicates.count
    duplicates.delete_all
    TicketVote.where(contact_id: @anonymous.id).update_all(contact_id: @identified.id)
    collapsed
  end

  def log_collapse(reads, votes)
    return unless reads.positive? || votes.positive?
    Rails.logger.info(
      "[ContactMergeService] merged anon=#{@anonymous.id} into identified=#{@identified.id}; " \
      "collapsed_reads=#{reads} collapsed_votes=#{votes}"
    )
  end
end
