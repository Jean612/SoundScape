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

require 'rails_helper'

RSpec.describe SearchAnalytic, type: :model do
  describe 'validations' do
    subject { build(:search_analytic) }

    it { should validate_presence_of(:query) }
    it { should validate_presence_of(:searched_at) }
    it { should validate_length_of(:query).is_at_least(1).is_at_most(100) }
  end

  describe 'associations' do
    it { should belong_to(:user) }
  end

  describe 'scopes' do
    let!(:user1) { create(:user, :confirmed) }
    let!(:user2) { create(:user, :confirmed) }
    let!(:search1) { create(:search_analytic, user: user1, query: "Beatles", searched_at: 2.hours.ago) }
    let!(:search2) { create(:search_analytic, user: user2, query: "Queen", searched_at: 1.hour.ago) }
    let!(:search3) { create(:search_analytic, user: user1, query: "Beatles", searched_at: 30.minutes.ago) }

    describe '.recent' do
      it 'orders by searched_at descending' do
        expect(SearchAnalytic.recent).to eq([search3, search2, search1])
      end
    end

    describe '.by_user' do
      it 'filters by user_id' do
        expect(SearchAnalytic.by_user(user1.id)).to contain_exactly(search1, search3)
      end
    end
  end

  describe '.trending_searches' do
    let!(:user) { create(:user, :confirmed) }
    
    before do
      create_list(:search_analytic, 3, user: user, query: "Beatles", searched_at: 2.hours.ago)
      create_list(:search_analytic, 2, user: user, query: "Queen", searched_at: 1.hour.ago)
      create(:search_analytic, user: user, query: "Pink Floyd", searched_at: 30.minutes.ago)
      create(:search_analytic, user: user, query: "Old Song", searched_at: 2.days.ago)
    end

    it 'returns trending searches within time period' do
      trending = SearchAnalytic.trending_searches(limit: 3, time_period: 24.hours)
      
      expect(trending["Beatles"]).to eq(3)
      expect(trending["Queen"]).to eq(2)
      expect(trending["Pink Floyd"]).to eq(1)
      expect(trending.keys).not_to include("Old Song")
    end

    it 'limits results correctly' do
      trending = SearchAnalytic.trending_searches(limit: 2, time_period: 24.hours)
      expect(trending.keys.size).to eq(2)
    end
  end

  describe 'factory' do
    it 'creates a valid search analytic' do
      search_analytic = build(:search_analytic)
      expect(search_analytic).to be_valid
    end
  end
end
