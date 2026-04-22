require "openssl"
require "jwt"

# Dev/test-only JWT signer.
#
# Production ideabug only verifies tokens, never mints them — signing is the host app's job.
# This helper exists so tests and the `_test/widget_host` harness can produce tokens locally
# without bleeding a private key into production configuration.
module JwtTestIssuer
  ALGORITHM = "RS256"
  EXPIRATION_TIME = 1.hour

  class << self
    def generate_token(contact, extra_claims = {})
      payload = {
        id: contact.external_id,
        exp: EXPIRATION_TIME.from_now.to_i,
        iat: Time.current.to_i,
        jti: SecureRandom.uuid
      }.merge(extra_claims)

      JWT.encode(payload, private_key, ALGORITHM)
    end

    def private_key
      @private_key ||= OpenSSL::PKey::RSA.new(
        ENV["JWT_PRIVATE_KEY"] ||
          File.read(Rails.root.join("config", "jwt", ENV.fetch("JWT_PRIVATE_KEY_FILE", "private.pem")))
      )
    end
  end
end
