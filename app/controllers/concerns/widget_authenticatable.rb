module WidgetAuthenticatable
  extend ActiveSupport::Concern

  ANON_HEADER = "X-Ideabug-Anon-Id".freeze
  ANON_ID_PATTERN = /\A[A-Za-z0-9_]{8,64}\z/

  included do
    before_action :authenticate_widget_request
    after_action :set_widget_response_headers
  end

  private

  def authenticate_widget_request
    anon_id = request.headers[ANON_HEADER].presence
    anon_id = nil unless anon_id.nil? || anon_id.match?(ANON_ID_PATTERN)
    bearer = request.authorization.to_s.split("Bearer ").last.presence

    jwt_data = nil
    if bearer
      begin
        jwt_data = JwtCredentialService.verify_token(bearer)
      rescue => e
        return render_widget_unauthorized("Invalid token: #{e.message}")
      end
    end

    external_id = jwt_data&.dig("id").presence

    if anon_id.blank? && external_id.blank?
      return render_widget_unauthorized("Identity required")
    end

    contact = resolve_contact(anon_id: anon_id, external_id: external_id)

    apply_jwt_payload(contact, jwt_data) if jwt_data
    contact.update_columns(last_seen_at: Time.current)

    Current.contact = contact
  end

  def resolve_contact(anon_id:, external_id:)
    if anon_id && external_id
      anon = Contact.find_by(anonymous_id: anon_id)
      identified = Contact.find_or_create_by!(external_id: external_id)
      if anon && anon != identified
        ContactMergeService.call(anonymous: anon, identified: identified)
      end
      identified
    elsif external_id
      Contact.find_or_create_by!(external_id: external_id)
    else
      Contact.find_or_create_by!(anonymous_id: anon_id)
    end
  end

  def apply_jwt_payload(contact, jwt_data)
    info = jwt_data["info"]
    contact.update!(info_payload: info) if info.present? && info != contact.info_payload

    segments = jwt_data["segments"]
    contact.update_segments_from_payload(segments) if segments.present?
  end

  def set_widget_response_headers
    return unless Current.contact
    response.headers["X-Ideabug-Contact-Id"] = Current.contact.id.to_s
    response.headers["X-Ideabug-Anonymous-Id"] = Current.contact.anonymous_id.to_s
    response.headers["X-Ideabug-Opted-Out"] = Current.contact.announcements_opted_out.to_s
  end

  def render_widget_unauthorized(message)
    render json: {error: message}, status: :unauthorized
  end
end
