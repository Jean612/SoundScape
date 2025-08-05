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

require 'rails_helper'

RSpec.describe PlaylistSong, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:position) }
    it { should validate_numericality_of(:position).is_greater_than(0) }
    
    it 'validates uniqueness of playlist_id scoped to song_id' do
      existing = create(:playlist_song)
      duplicate = build(:playlist_song, playlist: existing.playlist, song: existing.song)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:playlist_id]).to include('has already been taken')
    end
  end

  describe 'associations' do
    it { should belong_to(:playlist) }
    it { should belong_to(:song) }
  end

  describe 'factory' do
    it 'creates a valid playlist_song' do
      playlist_song = build(:playlist_song)
      expect(playlist_song).to be_valid
    end
  end
end
