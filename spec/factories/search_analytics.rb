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

FactoryBot.define do
  factory :search_analytic do
    association :user
    query { "Beatles Yesterday" }
    searched_at { Time.current }
    ip_address { Faker::Internet.ip_v4_address }
    results_count { rand(1..10) }
  end
end
