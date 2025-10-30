require "rails_helper"

RSpec.describe UserMailer, type: :mailer do
  describe "email_confirmation" do
    let(:user) { create(:user, name: "John Doe", email: "john@example.com") }
    let(:mail) { UserMailer.email_confirmation(user) }

    it "renders the headers" do
      expect(mail.subject).to eq("Confirm your SoundScape account")
      expect(mail.to).to eq([ "john@example.com" ])
      expect(mail.from).to eq([ "noreply@soundscape.com" ])
    end

    it "renders the body" do
      expect(mail.body.encoded).to match("Hi John Doe")
      expect(mail.body.encoded).to match("Welcome to SoundScape")
      expect(mail.body.encoded).to match("verification code")
      expect(mail.body.encoded).to match(user.otp_code)
    end
  end
end
