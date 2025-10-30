# A service for encoding and decoding JSON Web Tokens (JWT).
class JwtService
  SECRET_KEY = Rails.application.secret_key_base

  # Encodes a payload into a JWT token.
  #
  # @param payload [Hash] The data to encode in the token.
  # @param exp [ActiveSupport::TimeWithZone] The expiration time for the token.
  # @return [String] The encoded JWT token.
  def self.encode(payload, exp = 24.hours.from_now)
    payload[:exp] = exp.to_i
    JWT.encode(payload, SECRET_KEY)
  end

  # Decodes a JWT token.
  #
  # @param token [String] The JWT token to decode.
  # @return [HashWithIndifferentAccess] The decoded payload.
  # @raise [StandardError] If the token is invalid or expired.
  def self.decode(token)
    decoded = JWT.decode(token, SECRET_KEY)[0]
    HashWithIndifferentAccess.new(decoded)
  rescue JWT::DecodeError => e
    raise StandardError, "Invalid token: #{e.message}"
  end
end
