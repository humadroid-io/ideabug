require "openssl"
require "base64"
require "jwt"

module JwtConfig
  class << self
    def public_key
      @public_key ||= OpenSSL::PKey::RSA.new(raw_public_key)
    end

    private

    def raw_public_key
      if (b64 = ENV["JWT_PUBLIC_KEY_BASE64"].presence)
        Base64.decode64(b64)
      elsif (pem = ENV["JWT_PUBLIC_KEY"].presence)
        pem
      else
        File.read(Rails.root.join("config", "jwt", ENV.fetch("JWT_PUBLIC_KEY_FILE", "public.pem")))
      end
    end
  end
end
