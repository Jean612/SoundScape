class UserMailer < ApplicationMailer
  default from: "noreply@soundscape.com"

  def email_confirmation(user)
    @user = user
    @confirmation_url = confirmation_url(token: @user.email_confirmation_token)

    mail(
      to: @user.email,
      subject: "Confirm your SoundScape account"
    )
  end

  private

  def confirmation_url(token:)
    "#{Rails.application.config.app_host}/api/v1/auth/confirm_email?token=#{token}"
  end
end
