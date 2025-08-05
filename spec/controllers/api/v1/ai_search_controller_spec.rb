require 'rails_helper'

RSpec.describe Api::V1::AiSearchController, type: :controller do
  let(:user) { create(:user, :confirmed) }
  let(:token) { JWT.encode({ user_id: user.id }, Rails.application.secret_key_base, 'HS256') }
  let(:headers) { { 'Authorization' => "Bearer #{token}" } }

  before do
    request.headers.merge!(headers)
  end

  describe 'POST #search' do
    let(:valid_params) { { query: 'Beatles', limit: 5 } }

    context 'with valid authentication and parameters' do
      before do
        allow_any_instance_of(AiSearchService).to receive(:search_songs).and_return({
          success: true,
          songs: [
            {
              title: "Yesterday",
              artist: "The Beatles",
              album: "Help!",
              year: 1965,
              genre: "Pop",
              duration: "2:05",
              relevance_score: 0.95
            }
          ],
          query: "Beatles",
          cached: false,
          timestamp: Time.current
        })
      end

      it 'returns successful response' do
        post :search, params: valid_params
        
        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be true
        expect(json_response['data']['songs']).to be_an(Array)
        expect(json_response['data']['songs'].first['title']).to eq("Yesterday")
      end

      it 'tracks search analytics' do
        expect { post :search, params: valid_params }.to change(SearchAnalytic, :count).by(1)
        
        analytic = SearchAnalytic.last
        expect(analytic.user_id).to eq(user.id)
        expect(analytic.query).to eq("Beatles")
        expect(analytic.ip_address).to be_present
      end
    end

    context 'with cached results' do
      before do
        allow_any_instance_of(AiSearchService).to receive(:search_songs).and_return({
          success: true,
          songs: [{ title: "Cached Song", artist: "Cached Artist" }],
          query: "Beatles",
          cached: true,
          timestamp: Time.current
        })
      end

      it 'does not track analytics for cached results' do
        expect { post :search, params: valid_params }.not_to change(SearchAnalytic, :count)
      end

      it 'indicates cached results' do
        post :search, params: valid_params
        
        json_response = JSON.parse(response.body)
        expect(json_response['data']['cached']).to be true
      end
    end

    context 'with AI service failure' do
      before do
        allow_any_instance_of(AiSearchService).to receive(:search_songs).and_return({
          success: false,
          error: "AI service temporarily unavailable. Please try again later.",
          fallback: true
        })
      end

      it 'returns error response' do
        post :search, params: valid_params
        
        expect(response).to have_http_status(:unprocessable_content)
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be false
        expect(json_response['error']).to include("AI service temporarily unavailable")
      end
    end

    context 'with rate limiting' do
      before do
        allow_any_instance_of(AiSearchService).to receive(:search_songs).and_return({
          success: false,
          error: "Rate limit exceeded. Please try again later.",
          rate_limited: true
        })
      end

      it 'returns rate limited response' do
        post :search, params: valid_params
        
        expect(response).to have_http_status(:too_many_requests)
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be false
        expect(json_response['rate_limited']).to be true
      end
    end

    context 'without authentication' do
      before do
        request.headers['Authorization'] = nil
      end

      it 'returns unauthorized' do
        post :search, params: valid_params
        
        expect(response).to have_http_status(:unauthorized)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Missing token')
      end
    end

    context 'with unconfirmed email' do
      let(:unconfirmed_user) { create(:user, email_confirmed: false) }
      let(:unconfirmed_token) { JWT.encode({ user_id: unconfirmed_user.id }, Rails.application.secret_key_base, 'HS256') }

      before do
        request.headers['Authorization'] = "Bearer #{unconfirmed_token}"
      end

      it 'returns forbidden' do
        post :search, params: valid_params
        
        expect(response).to have_http_status(:forbidden)
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Access denied')
      end
    end
  end

  describe 'GET #trending' do
    let!(:user1) { create(:user, :confirmed) }
    let!(:user2) { create(:user, :confirmed) }

    before do
      create_list(:search_analytic, 3, user: user1, query: "Beatles", searched_at: 2.hours.ago)
      create_list(:search_analytic, 2, user: user2, query: "Queen", searched_at: 1.hour.ago)
      create(:search_analytic, user: user1, query: "Pink Floyd", searched_at: 30.minutes.ago)
    end

    it 'returns trending searches' do
      get :trending
      
      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response['success']).to be true
      expect(json_response['data']['trending_searches']).to be_present
      expect(json_response['data']['trending_searches']['Beatles']).to eq(3)
    end

    it 'respects limit parameter' do
      get :trending, params: { limit: 2 }
      
      json_response = JSON.parse(response.body)
      expect(json_response['data']['trending_searches'].keys.size).to eq(2)
    end

    it 'respects time_period parameter' do
      get :trending, params: { time_period: 1 }
      
      json_response = JSON.parse(response.body)
      expect(json_response['data']['time_period_hours']).to eq(1)
    end
  end

  describe 'GET #user_history' do
    let!(:search1) { create(:search_analytic, user: user, query: "Beatles", searched_at: 2.hours.ago) }
    let!(:search2) { create(:search_analytic, user: user, query: "Queen", searched_at: 1.hour.ago) }
    let!(:other_user_search) { create(:search_analytic, query: "Pink Floyd", searched_at: 30.minutes.ago) }

    it 'returns user search history' do
      get :user_history
      
      expect(response).to have_http_status(:ok)
      json_response = JSON.parse(response.body)
      expect(json_response['success']).to be true
      expect(json_response['data']['searches'].size).to eq(2)
      expect(json_response['data']['searches'].first['query']).to eq("Queen") # Most recent first
    end

    it 'paginates results' do
      get :user_history, params: { page: 1, per_page: 1 }
      
      json_response = JSON.parse(response.body)
      expect(json_response['data']['searches'].size).to eq(1)
      expect(json_response['data']['pagination']['page']).to eq(1)
      expect(json_response['data']['pagination']['per_page']).to eq(1)
      expect(json_response['data']['pagination']['total_count']).to eq(2)
    end

    it 'only returns current user searches' do
      get :user_history
      
      json_response = JSON.parse(response.body)
      queries = json_response['data']['searches'].map { |s| s['query'] }
      expect(queries).to contain_exactly("Beatles", "Queen")
      expect(queries).not_to include("Pink Floyd")
    end
  end
end