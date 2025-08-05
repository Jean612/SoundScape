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

require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    subject { build(:user) }

    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email) }
    it { should allow_value('user@example.com').for(:email) }
    it { should_not allow_value('invalid_email').for(:email) }
    
    it { should validate_presence_of(:username) }
    it { should validate_uniqueness_of(:username) }
    
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:country) }
    it { should validate_presence_of(:birth_date) }
    
    it { should have_secure_password }
  end

  describe 'associations' do
    it { should have_many(:playlists).dependent(:destroy) }
  end

  describe 'factory' do
    it 'creates a valid user' do
      user = build(:user)
      expect(user).to be_valid
    end
  end
end
