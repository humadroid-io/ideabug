module Api
  module V1
    class IdentityController < BaseController
      skip_before_action :authenticate_widget_request, only: :create
      skip_after_action :set_widget_response_headers, only: :create

      def create
        bearer = request.authorization.to_s.split("Bearer ").last.presence
        jwt_data = bearer ? safely_verify(bearer) : nil
        external_id = jwt_data&.dig("id").presence
        anon_id = request.headers[WidgetAuthenticatable::ANON_HEADER].presence
        anon_id = nil if anon_id && !anon_id.match?(WidgetAuthenticatable::ANON_ID_PATTERN)

        contact = mint_or_resolve(anon_id: anon_id, external_id: external_id)
        apply_jwt(contact, jwt_data) if jwt_data
        contact.update_columns(last_seen_at: Time.current)

        Current.contact = contact
        response.headers["X-Ideabug-Contact-Id"] = contact.id.to_s
        response.headers["X-Ideabug-Opted-Out"] = contact.announcements_opted_out.to_s

        render json: {
          anonymous_id: contact.anonymous_id,
          external_id: contact.external_id,
          identified: contact.identified?,
          opted_out: contact.announcements_opted_out,
          contact_id: contact.id
        }
      end

      private

      def mint_or_resolve(anon_id:, external_id:)
        if external_id && anon_id
          anon = Contact.find_by(anonymous_id: anon_id)
          identified = Contact.find_or_create_by!(external_id: external_id)
          ContactMergeService.call(anonymous: anon, identified: identified) if anon && anon != identified
          identified
        elsif external_id
          Contact.find_or_create_by!(external_id: external_id)
        elsif anon_id
          Contact.find_or_create_by!(anonymous_id: anon_id)
        else
          Contact.create!(anonymous_id: generate_anonymous_id)
        end
      end

      def generate_anonymous_id
        "ib_#{SecureRandom.alphanumeric(22)}"
      end

      def safely_verify(token)
        JwtCredentialService.verify_token(token)
      rescue
        nil
      end

      def apply_jwt(contact, jwt_data)
        info = jwt_data["info"]
        contact.update!(info_payload: info) if info.present? && info != contact.info_payload

        segments = jwt_data["segments"]
        contact.update_segments_from_payload(segments) if segments.present?
      end
    end
  end
end
