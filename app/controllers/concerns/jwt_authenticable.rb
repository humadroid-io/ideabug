module JwtAuthenticatable
  extend ActiveSupport::Concern

  def authenticate_jwt_token
    token = extract_token_from_params
    @current_user_data = JwtCredentialService.verify_token(token)
  rescue => e
    render json: {error: "Authentication failed: #{e.message}"}, status: :unauthorized
  end

  private

  def extract_token_from_params
    params.require(:token)
  end
end
