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

require 'rails_helper'

RSpec.describe Song, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:artist) }
    it { should validate_presence_of(:duration_seconds) }
    it { should validate_numericality_of(:duration_seconds).is_greater_than(0) }
  end

  describe 'associations' do
    it { should have_many(:playlist_songs).dependent(:destroy) }
    it { should have_many(:playlists).through(:playlist_songs) }
  end

  describe 'factory' do
    it 'creates a valid song' do
      song = build(:song)
      expect(song).to be_valid
    end
  end
end
