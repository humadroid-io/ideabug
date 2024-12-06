json.extract! contact, :id, :external_id, :info_payload, :created_at, :updated_at
json.url contact_url(contact, format: :json)
