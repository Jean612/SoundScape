# == Schema Information
#
# Table name: songs
#
#  id               :integer          not null, primary key
#  title            :string
#  artist           :string
#  album            :string
#  duration_seconds :integer
#  spotify_id       :string
#  youtube_id       :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

FactoryBot.define do
  factory :song do
    title { Faker::Lorem.words(number: 3).join(' ').titleize }
    artist { Faker::Name.name }
    album { Faker::Lorem.words(number: 2).join(' ').titleize }
    duration_seconds { Faker::Number.between(from: 60, to: 360) }
    spotify_id { Faker::Alphanumeric.alphanumeric(number: 22) }
    youtube_id { Faker::Alphanumeric.alphanumeric(number: 11) }
  end
end
