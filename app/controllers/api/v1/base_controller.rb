module Api
  module V1
    class BaseController < ApplicationController
      include ActionController::MimeResponds
      include WidgetAuthenticatable

      skip_before_action :require_authentication
      skip_before_action :verify_authenticity_token

      rescue_from ActiveRecord::RecordNotFound, with: :not_found
      rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity

      private

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
