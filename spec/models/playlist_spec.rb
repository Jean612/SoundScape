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

require 'rails_helper'

RSpec.describe Playlist, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:name) }
  end

  describe 'associations' do
    it { should belong_to(:user) }
    it { should have_many(:playlist_songs).dependent(:destroy) }
    it { should have_many(:songs).through(:playlist_songs) }
    it { should have_many(:exports).dependent(:destroy) }
  end

  describe 'factory' do
    it 'creates a valid playlist' do
      playlist = build(:playlist)
      expect(playlist).to be_valid
    end
  end
end
