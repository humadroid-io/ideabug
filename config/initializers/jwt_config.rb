require "openssl"
require "jwt"

module JwtConfig
  class << self
    def public_key
      @public_key ||= OpenSSL::PKey::RSA.new(
        ENV["JWT_PUBLIC_KEY"] ||
          File.read(Rails.root.join("config", "jwt", ENV.fetch("JWT_PUBLIC_KEY_FILE", "public.pem")))
      )
    end
  end
end
