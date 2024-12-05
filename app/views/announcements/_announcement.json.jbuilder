json.extract! announcement, :id, :title, :preview, :created_at, :updated_at
json.content announcement.content.to_s
json.url announcement_url(announcement, format: :json)
