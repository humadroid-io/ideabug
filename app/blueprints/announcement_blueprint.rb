class AnnouncementBlueprint < Blueprinter::Base
  identifier :id
  fields :title, :preview, :content, :read
end
