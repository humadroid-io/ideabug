class TicketBlueprint < Blueprinter::Base
  identifier :id
  fields :title, :description, :classification, :status, :votes_count,
    :public_on_roadmap, :scheduled_for, :shipped_at, :created_at

  field :voted_by_me do |ticket, options|
    contact = options[:contact]
    next false unless contact
    if ticket.respond_to?(:voted_by_me) && !ticket.voted_by_me.nil?
      ticket.voted_by_me
    else
      ticket.ticket_votes.exists?(contact_id: contact.id)
    end
  end
end
