require 'rails_helper'

RSpec.describe Api::V1::AiSearchController, type: :controller do
  let(:user) { create(:user, :confirmed) }
  let(:token) { JWT.encode({ user_id: user.id }, Rails.application.secret_key_base, 'HS256') }
  let(:headers) { { 'Authorization' => "Bearer #{token}" } }

  before do
    request.headers.merge!(headers)
    ENV['OPENAI_API_KEY'] = 'test-key'
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

      it 'returns http ok status' do
        post :search, params: valid_params

        expect(response).to have_http_status(:ok)
      end

      it 'returns song data' do
        post :search, params: valid_params

        expect(JSON.parse(response.body)).to match(
          hash_including('success' => true,
                        'data' => hash_including('songs' => [hash_including('title' => 'Yesterday')]))
        )
      end

      it 'creates analytics record' do
        expect { post :search, params: valid_params }.to change(SearchAnalytic, :count).by(1)
      end

      it 'stores correct analytics data' do
        post :search, params: valid_params

        expect(SearchAnalytic.last).to have_attributes(user_id: user.id, query: 'Beatles')
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

      it 'returns unprocessable content status' do
        post :search, params: valid_params

        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'returns fallback error message' do
        post :search, params: valid_params

        expect(JSON.parse(response.body)['error']).to include('AI service temporarily unavailable')
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

      it 'returns too many requests status' do
        post :search, params: valid_params

        expect(response).to have_http_status(:too_many_requests)
      end

      it 'returns rate limit flag' do
        post :search, params: valid_params

        expect(JSON.parse(response.body)['rate_limited']).to be true
      end
    end

    context 'without authentication' do
      before do
        request.headers['Authorization'] = nil
      end

      it 'returns unauthorized status' do
        post :search, params: valid_params

        expect(response).to have_http_status(:unauthorized)
      end

      it 'returns missing token message' do
        post :search, params: valid_params

        expect(JSON.parse(response.body)['error']).to eq('Missing token')
      end
    end

    context 'with unconfirmed email' do
      let(:unconfirmed_user) { create(:user, email_confirmed: false) }
      let(:unconfirmed_token) { JWT.encode({ user_id: unconfirmed_user.id }, Rails.application.secret_key_base, 'HS256') }

      before do
        request.headers['Authorization'] = "Bearer #{unconfirmed_token}"
      end

      it 'returns forbidden status' do
        post :search, params: valid_params

        expect(response).to have_http_status(:forbidden)
      end

      it 'returns access denied message' do
        post :search, params: valid_params

        expect(JSON.parse(response.body)['error']).to eq('Access denied')
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

    it 'returns ok status for trending' do
      get :trending

      expect(response).to have_http_status(:ok)
    end

    it 'returns trending data' do
      get :trending

      expect(JSON.parse(response.body)['data']['trending_searches']).to include('Beatles' => 3)
    end

    it 'respects limit parameter' do
      get :trending, params: { limit: 2 }

      expect(JSON.parse(response.body)['data']['trending_searches'].keys.size).to eq(2)
    end

    it 'respects time_period parameter' do
      get :trending, params: { time_period: 1 }

      expect(JSON.parse(response.body)['data']['time_period_hours']).to eq(1)
    end
  end

  describe 'GET #user_history' do
    let!(:search1) { create(:search_analytic, user: user, query: "Beatles", searched_at: 2.hours.ago) }
    let!(:search2) { create(:search_analytic, user: user, query: "Queen", searched_at: 1.hour.ago) }
    let!(:other_user_search) { create(:search_analytic, query: "Pink Floyd", searched_at: 30.minutes.ago) }

    it 'returns ok status for user history' do
      get :user_history

      expect(response).to have_http_status(:ok)
    end

    it 'returns two user searches' do
      get :user_history

      expect(JSON.parse(response.body)['data']['searches'].size).to eq(2)
    end

    it 'returns most recent search first' do
      get :user_history

      expect(JSON.parse(response.body)['data']['searches'].first['query']).to eq('Queen')
    end

    it 'paginates results' do
      get :user_history, params: { page: 1, per_page: 1 }

      expect(JSON.parse(response.body)['data']['pagination']).to include('page' => 1, 'per_page' => 1, 'total_count' => 2)
    end

    it 'only returns current user searches' do
      get :user_history

      queries = JSON.parse(response.body)['data']['searches'].map { |s| s['query'] }
      expect(queries).to match_array(%w[Beatles Queen])
    end
  end
end