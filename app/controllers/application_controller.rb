# The base controller for the API.
# It handles request authentication and authorization.
class ApplicationController < ActionController::API
  include CanCan::ControllerAdditions

  before_action :authenticate_request
  attr_reader :current_user

  rescue_from CanCan::AccessDenied do |exception|
    render json: { error: "Access denied: #{exception.message}" }, status: :forbidden
  end

  private

  # Authenticates the user for the request.
  #
  # @return [void]
  def authenticate_request
    result = AuthorizeApiRequest.new(request.headers).call
    @current_user = result if result
  rescue StandardError => e
    render json: { error: e.message }, status: :unauthorized
  end

  # Authorizes the request based on a provided token.
  #
  # @param token [String, nil] The JWT token to authorize.
  # @return [void]
  # @raise [StandardError] If the user is not found.
  def authorize_request(token = nil)
    return if token.nil?

    decoded = JwtService.decode(token)
    @current_user = User.find(decoded[:user_id])
  rescue ActiveRecord::RecordNotFound
    raise StandardError, 'User not found'
  end

  # Returns the ability object for the current user.
  #
  # @return [Ability] The ability object for the current user.
  def current_ability
    @current_ability ||= Ability.new(current_user&.dig(:user))
  end
end
