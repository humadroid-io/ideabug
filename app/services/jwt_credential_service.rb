class JwtCredentialService
  ALGORITHM = "RS256"
  EXPIRATION_TIME = 1.hour

  def self.generate_token(user)
    payload = {
      email: user.email_address,
      user_id: user.id,
      exp: EXPIRATION_TIME.from_now.to_i,
      iat: Time.current.to_i,
      jti: SecureRandom.uuid
    }

    JWT.encode(payload, JwtConfig.private_key, ALGORITHM)
  end

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
