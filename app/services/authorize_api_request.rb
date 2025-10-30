# A service object to authorize API requests.
# It validates the JWT token from the request headers and returns the authenticated user.
class AuthorizeApiRequest
  # Initializes the service with the request headers.
  #
  # @param headers [Hash] The request headers, including the 'Authorization' header.
  def initialize(headers = {})
    @headers = headers
  end

  # The main entry point for the service.
  #
  # @return [Hash] A hash containing the authenticated user.
  def call
    {
      user: user
    }
  end

  private

  attr_reader :headers

  def user
    @user ||= User.find(decoded_auth_token[:user_id]) if decoded_auth_token
  rescue ActiveRecord::RecordNotFound => e
    raise StandardError, 'Invalid token'
  end

  def decoded_auth_token
    @decoded_auth_token ||= JwtService.decode(http_auth_header)
  end

  def http_auth_header
    if headers['Authorization'].present?
      return headers['Authorization'].split(' ').last
    end
    raise StandardError, 'Missing token'
  end
end
