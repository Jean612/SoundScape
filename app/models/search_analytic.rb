# == Schema Information
#
# Table name: search_analytics
#
#  id            :integer          not null, primary key
#  user_id       :integer          not null
#  query         :string
#  searched_at   :datetime
#  ip_address    :string
#  results_count :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_search_analytics_on_user_id  (user_id)
#

# Records search queries made by users for analytics purposes.
class SearchAnalytic < ApplicationRecord
  belongs_to :user

  validates :query, presence: true, length: { minimum: 1, maximum: 100 }
  validates :searched_at, presence: true

  scope :recent, -> { order(searched_at: :desc) }
  scope :by_user, ->(user_id) { where(user_id: user_id) }
  scope :popular_queries, -> { group(:query).count.sort_by(&:last).reverse.to_h }

  # Returns the most frequent search queries within a given time period.
  #
  # @param limit [Integer] The maximum number of trending searches to return.
  # @param time_period [ActiveSupport::Duration] The time window to consider for trending searches.
  # @return [Hash] A hash of trending queries and their counts.
  def self.trending_searches(limit: 10, time_period: 24.hours)
    where(searched_at: time_period.ago..Time.current)
      .group(:query)
      .count
      .sort_by(&:last)
      .reverse
      .first(limit)
      .to_h
  end
end
