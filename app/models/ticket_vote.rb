# frozen_string_literal: true

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
class TicketVote < ApplicationRecord
  ## SCOPES
  ## CONCERNS
  ## CONSTANTS
  ## ATTRIBUTES & RELATED
  ## ASSOCIATIONS
  belongs_to :ticket, counter_cache: :votes_count
  belongs_to :contact
  ## VALIDATIONS
  validates :contact_id, uniqueness: {scope: :ticket_id}
  ## CALLBACKS
  before_validation :set_voted_at, on: :create
  ## OTHER

  private

  def set_voted_at
    self.voted_at ||= Time.current
  end
end
