# == Schema Information
#
# Table name: playlist_songs
#
#  id          :integer          not null, primary key
#  playlist_id :integer          not null
#  song_id     :integer          not null
#  position    :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_playlist_songs_on_playlist_id  (playlist_id)
#  index_playlist_songs_on_song_id      (song_id)
#

FactoryBot.define do
  factory :playlist_song do
    association :playlist
    association :song
    position { Faker::Number.between(from: 1, to: 50) }
  end
end
