# == Schema Information
#
# Table name: users
#
#  id                           :integer          not null, primary key
#  email                        :string
#  password_digest              :string
#  google_id                    :string
#  name                         :string
#  username                     :string
#  birth_date                   :date
#  country                      :string
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  email_confirmed              :boolean          default(FALSE), not null
#  email_confirmation_token     :string
#  email_confirmation_sent_at   :datetime
#
# Indexes
#
#  index_users_on_email                    (email) UNIQUE
#  index_users_on_username                 (username) UNIQUE
#  index_users_on_email_confirmation_token (email_confirmation_token) UNIQUE
#

class User < ApplicationRecord
  has_secure_password

  has_many :playlists, dependent: :destroy
  has_many :search_analytics, dependent: :destroy

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :username, presence: true, uniqueness: true
  validates :name, presence: true
  validates :country, presence: true
  validates :birth_date, presence: true

  before_create :generate_otp_code
  after_create :send_email_confirmation

  def generate_otp_code
    self.otp_code = sprintf('%06d', SecureRandom.random_number(1_000_000))
    self.otp_expires_at = 15.minutes.from_now
    self.email_confirmation_token = SecureRandom.urlsafe_base64
    self.email_confirmation_sent_at = Time.current
  end

  def send_email_confirmation
    UserMailer.email_confirmation(self).deliver_now
  end

  def verify_otp(code)
    return false if otp_expired?
    return false if otp_code != code
    
    confirm_email!
    true
  end

  def confirm_email!
    update!(
      email_confirmed: true, 
      email_confirmation_token: nil,
      otp_code: nil,
      otp_expires_at: nil
    )
  end

  def email_confirmed?
    email_confirmed
  end

  def otp_expired?
    otp_expires_at.nil? || otp_expires_at < Time.current
  end

  def email_confirmation_expired?
    email_confirmation_sent_at < 24.hours.ago
  end

  def resend_otp_code
    generate_otp_code
    save!
    send_email_confirmation
  end

  def generate_email_confirmation_token
    self.email_confirmation_token = SecureRandom.urlsafe_base64
    self.email_confirmation_sent_at = Time.current
  end

  def resend_email_confirmation
    generate_email_confirmation_token
    save!
    send_email_confirmation
  end
end
