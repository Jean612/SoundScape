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

# Represents a song in the music library.
class Song < ApplicationRecord
  has_many :playlist_songs, dependent: :destroy
  has_many :playlists, through: :playlist_songs

  validates :title, presence: true
  validates :artist, presence: true
  validates :duration_seconds, presence: true, numericality: { greater_than: 0 }
end
