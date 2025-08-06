class Api::V1::EmailConfirmationsController < ApplicationController
  skip_before_action :authenticate_request

  def confirm
    user = User.find_by(email_confirmation_token: params[:token])

    if user.nil?
      render json: { error: "Invalid confirmation token" }, status: :not_found
    elsif user.email_confirmed?
      render json: { message: "Email already confirmed" }, status: :ok
    elsif user.email_confirmation_expired?
      render json: { error: "Confirmation token has expired" }, status: :unprocessable_content
    else
      user.confirm_email!
      render json: { message: "Email confirmed successfully" }, status: :ok
    end
  end

  def resend
    user = User.find_by(email: params[:email])

    if user.nil?
      render json: { error: "User not found" }, status: :not_found
    elsif user.email_confirmed?
      render json: { message: "Email already confirmed" }, status: :ok
    else
      user.resend_email_confirmation
      render json: { message: "Confirmation email sent" }, status: :ok
    end
  end
end
