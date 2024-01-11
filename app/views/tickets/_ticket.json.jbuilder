json.extract! ticket, :id, :title, :description, :status, :classification, :created_at, :updated_at
json.url ticket_url(ticket, format: :json)
