class JwtCredentialService
  ALGORITHM = "RS256"

  def self.verify_token(token)
    decoded_token = JWT.decode(
      token,
      JwtConfig.public_key,
      true,
      {
        algorithm: ALGORITHM,
        verify_expiration: true,
        verify_iat: true
      }
    )

    decoded_token.first
  rescue JWT::ExpiredSignature
    raise "Token has expired"
  rescue JWT::InvalidIatError
    raise "Invalid issued at time"
  rescue JWT::VerificationError
    raise "Token verification failed"
  rescue JWT::DecodeError
    raise "Invalid token"
  end
end
