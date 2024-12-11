module Api
  module V1
    class BaseController < ApplicationController
      include ActionController::MimeResponds

      before_action :authenticate_jwt_token
      skip_before_action :require_authentication
      skip_before_action :verify_authenticity_token

      rescue_from ActiveRecord::RecordNotFound, with: :not_found
      rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity

      private

      def authenticate_jwt_token
        token = extract_token_from_params
        @current_user_data = JwtCredentialService.verify_token(token)
        raise ActiveRecord::RecordInvalid unless @current_user_data["id"].present?
        @current_contact = Contact.find_or_create_by(external_id: @current_user_data["id"])
        if @current_user_data["info"].present? && @current_user_data["info"].any?
          @current_contact.update(info_payload: @current_user_data["info"])
        end
        if @current_user_data["segments"].present? && @current_user_data["segments"].any?
          @current_contact.update_segments_from_payload(@current_user_data["segments"])
        end
        Current.contact = @current_contact
      rescue => e
        render json: {error: "Authentication failed: #{e.message}"}, status: :unauthorized
      end

      def extract_token_from_params
        request.headers["Authorization"].to_s.split("Bearer ").last
      end

      def not_found
        render json: {
          errors: [{
            status: "404",
            title: "Not Found",
            detail: "The requested resource could not be found"
          }]
        }, status: :not_found
      end

      def unprocessable_entity(exception)
        render json: {
          errors: [{
            status: "422",
            title: "Unprocessable Entity",
            detail: exception.record.errors.full_messages.join(", ")
          }]
        }, status: :unprocessable_entity
      end
    end
  end
end
