# == Schema Information
#
# Table name: playlists
#
#  id          :integer          not null, primary key
#  user_id     :integer          not null
#  name        :string
#  description :text
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_playlists_on_user_id  (user_id)
#

FactoryBot.define do
  factory :playlist do
    association :user
    name { Faker::Lorem.words(number: 2).join(' ').titleize }
    description { Faker::Lorem.paragraph }
  end
end
