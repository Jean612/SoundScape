# Handles user authentication, including registration and login.
class Api::V1::AuthenticationController < ApplicationController
  skip_before_action :authenticate_request, only: [:login, :register]

  # Authenticates a user and returns a JWT token if successful.
  # The user must have a confirmed email address to log in.
  #
  # @param user [Hash] The user's login credentials.
  # @option user [String] :email The user's email address.
  # @option user [String] :password The user's password.
  # @return [JSON] A JSON response containing the JWT token and user data, or an error message.
  def login
    user = User.find_by(email: login_params[:email])

    if user&.authenticate(login_params[:password])
      unless user.email_confirmed?
        return render json: {
          error: 'Please confirm your email address before logging in',
          email_confirmed: false
        }, status: :unauthorized
      end

      token = JwtService.encode(user_id: user.id)
      render json: {
        token: token,
        user: user_response(user)
      }, status: :ok
    else
      render json: { error: 'Invalid credentials' }, status: :unauthorized
    end
  end

  # Registers a new user.
  # On successful registration, an email confirmation is sent to the user.
  #
  # @param user [Hash] The user's registration data.
  # @option user [String] :email The user's email address.
  # @option user [String] :password The user's password.
  # @option user [String] :name The user's full name.
  # @option user [String] :username The user's username.
  # @option user [Date] :birth_date The user's date of birth.
  # @option user [String] :country The user's country.
  # @return [JSON] A JSON response indicating the result of the registration.
  def register
    user = User.new(register_params)

    if user.save
      render json: {
        message: 'User created successfully. Please check your email to confirm your account.',
        user: user_response(user),
        email_confirmed: false
      }, status: :created
    else
      render json: { errors: user.errors.full_messages }, status: :unprocessable_content
    end
  end

  private

  # Strong parameters for the login action.
  #
  # @return [ActionController::Parameters] The permitted parameters for login.
  def login_params
    params.require(:user).permit(:email, :password)
  end

  # Strong parameters for the register action.
  #
  # @return [ActionController::Parameters] The permitted parameters for registration.
  def register_params
    params.require(:user).permit(:email, :password, :name, :username, :birth_date, :country)
  end

  # Formats the user data for JSON responses.
  #
  # @param user [User] The user object.
  # @return [Hash] A hash containing the user's public data.
  def user_response(user)
    {
      id: user.id,
      email: user.email,
      name: user.name,
      username: user.username,
      country: user.country,
      birth_date: user.birth_date,
      email_confirmed: user.email_confirmed?
    }
  end
end
