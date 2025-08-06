class Api::V1::EmailConfirmationsController < ApplicationController
  skip_before_action :authenticate_request

  def verify_otp
    user = User.find_by(email: params[:email])
    otp_code = params[:otp_code]

    if user.nil?
      render json: { error: "User not found" }, status: :not_found
    elsif user.email_confirmed?
      render json: { message: "Email already confirmed" }, status: :ok
    elsif otp_code.blank?
      render json: { error: "OTP code is required" }, status: :unprocessable_content
    elsif user.verify_otp(otp_code)
      render json: { message: "Email confirmed successfully" }, status: :ok
    elsif user.otp_expired?
      render json: { error: "OTP code has expired" }, status: :unprocessable_content
    else
      render json: { error: "Invalid OTP code" }, status: :unprocessable_content
    end
  end

  def resend_otp
    user = User.find_by(email: params[:email])

    if user.nil?
      render json: { error: "User not found" }, status: :not_found
    elsif user.email_confirmed?
      render json: { message: "Email already confirmed" }, status: :ok
    else
      user.resend_otp_code
      render json: { message: "New OTP code sent to your email" }, status: :ok
    end
  end

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
