class Current < ActiveSupport::CurrentAttributes
  attribute :session
  attribute :contact
  delegate :user, to: :session, allow_nil: true
end
