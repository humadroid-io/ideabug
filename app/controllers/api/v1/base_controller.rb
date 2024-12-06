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
