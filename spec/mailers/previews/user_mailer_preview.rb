# Preview all emails at http://localhost:3000/rails/mailers/user_mailer_mailer
class UserMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/user_mailer_mailer/email_confirmation
  def email_confirmation
    UserMailer.email_confirmation
  end
end
