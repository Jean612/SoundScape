class ApplicationController < ActionController::API
  include CanCan::ControllerAdditions
  
  before_action :authenticate_request
  attr_reader :current_user

  rescue_from CanCan::AccessDenied do |exception|
    render json: { error: "Access denied: #{exception.message}" }, status: :forbidden
  end

  private

  def authenticate_request
    result = AuthorizeApiRequest.new(request.headers).call
    @current_user = result if result
  rescue StandardError => e
    render json: { error: e.message }, status: :unauthorized
  end

  def authorize_request(token = nil)
    return if token.nil?

    decoded = JwtService.decode(token)
    @current_user = User.find(decoded[:user_id])
  rescue ActiveRecord::RecordNotFound
    raise StandardError, 'User not found'
  end

  def current_ability
    @current_ability ||= Ability.new(current_user&.dig(:user))
  end
end
