class AnnouncementBlueprint < Blueprinter::Base
  identifier :id
  fields :title, :preview, :read, :published_at

  field :read_at do |obj|
    if obj.respond_to?(:read_at) && !obj.read_at.nil?
      obj.read_at
    elsif obj.respond_to?(:announcement_reads)
      obj.announcement_reads.where(contact_id: Current.contact&.id).first&.read_at
    end
  end

  # Detail view — used by the show action and by the widget's modal. Adds
  # the rich-text body which is the heaviest field per row.
  view :detail do
    field :content
  end
end
