class RoadmapTicketBlueprint < Blueprinter::Base
  identifier :id
  fields :title, :classification, :status, :scheduled_for, :shipped_at, :votes_count
end
