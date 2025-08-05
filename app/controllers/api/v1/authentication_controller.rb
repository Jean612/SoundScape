class Api::V1::AuthenticationController < ApplicationController
  skip_before_action :authenticate_request, only: [:login, :register]

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

  def login_params
    params.require(:user).permit(:email, :password)
  end

  def register_params
    params.require(:user).permit(:email, :password, :name, :username, :birth_date, :country)
  end

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
