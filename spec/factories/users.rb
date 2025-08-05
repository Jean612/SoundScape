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

FactoryBot.define do
  factory :user do
    email { Faker::Internet.unique.email }
    password { "password123" }
    google_id { nil }
    name { Faker::Name.name }
    username { Faker::Internet.unique.username(specifier: 5..8) }
    birth_date { Faker::Date.birthday(min_age: 18, max_age: 65) }
    country { Faker::Address.country }
    email_confirmed { false }

    trait :confirmed do
      email_confirmed { true }
    end
  end
end
