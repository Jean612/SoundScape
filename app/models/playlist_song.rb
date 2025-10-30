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

# Represents the join table between playlists and songs, indicating a song's position in a playlist.
class PlaylistSong < ApplicationRecord
  belongs_to :playlist
  belongs_to :song

  validates :position, presence: true, numericality: { greater_than: 0 }
  validates :playlist_id, uniqueness: { scope: :song_id }
end
