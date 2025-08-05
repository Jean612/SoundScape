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

require 'rails_helper'

RSpec.describe Export, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:platform) }
    it { should validate_inclusion_of(:platform).in_array(%w[spotify youtube_music]) }
    it { should validate_presence_of(:external_id) }
    it { should validate_presence_of(:exported_at) }
  end

  describe 'associations' do
    it { should belong_to(:playlist) }
  end

  describe 'factory' do
    it 'creates a valid export' do
      export = build(:export)
      expect(export).to be_valid
    end
  end
end
