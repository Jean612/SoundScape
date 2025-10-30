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

# Represents an export of a playlist to an external platform like Spotify or YouTube Music.
class Export < ApplicationRecord
  belongs_to :playlist

  validates :platform, presence: true, inclusion: { in: %w[spotify youtube_music] }
  validates :external_id, presence: true
  validates :exported_at, presence: true
end
