# == Schema Information
#
# Table name: exports
#
#  id          :integer          not null, primary key
#  playlist_id :integer          not null
#  platform    :string
#  external_id :string
#  exported_at :datetime
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_exports_on_playlist_id  (playlist_id)
#

FactoryBot.define do
  factory :export do
    association :playlist
    platform { ['spotify', 'youtube_music'].sample }
    external_id { Faker::Alphanumeric.alphanumeric(number: 20) }
    exported_at { Faker::Time.backward(days: 30) }
  end
end
