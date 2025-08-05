require 'rails_helper'

RSpec.describe AiSearchService, type: :service do
  let(:user) { create(:user, :confirmed) }
  let(:query) { "Beatles" }
  let(:service) { AiSearchService.new(query: query, user_id: user.id, limit: 5) }

  describe '#search_songs' do
    context 'with valid query' do
      before do
        allow_any_instance_of(AiSearchService).to receive(:generate_ai_suggestions).and_return(
          '[{"title":"Yesterday","artist":"The Beatles","album":"Help!","year":1965,"genre":"Pop","duration":"2:05","relevance_score":0.95}]'
        )
      end

      it 'returns successful response with songs' do
        result = service.search_songs
        
        expect(result[:success]).to be true
        expect(result[:songs]).to be_an(Array)
        expect(result[:songs].first[:title]).to eq("Yesterday")
        expect(result[:songs].first[:artist]).to eq("The Beatles")
        expect(result[:cached]).to be false
      end

      it 'caches the results' do
        expect(Rails.cache).to receive(:write).with(anything, anything, expires_in: 1.hour).at_least(:once)
        service.search_songs
      end

      it 'tracks search analytics' do
        expect { service.search_songs }.to change(SearchAnalytic, :count).by(1)
        
        analytic = SearchAnalytic.last
        expect(analytic.user_id).to eq(user.id)
        expect(analytic.query).to eq(query)
      end
    end

    context 'with cached results' do
      let(:cached_songs) { [{ title: "Cached Song", artist: "Cached Artist" }] }

      before do
        allow(Rails.cache).to receive(:read).with(service.send(:cache_key)).and_return(cached_songs)
        allow(Rails.cache).to receive(:read).with("rate_limit:ai_search:#{user.id}").and_return(0)
      end

      it 'returns cached results' do
        result = service.search_songs
        
        expect(result[:success]).to be true
        expect(result[:songs]).to eq(cached_songs)
        expect(result[:cached]).to be true
      end

      it 'does not call AI service when cached' do
        expect_any_instance_of(AiSearchService).not_to receive(:generate_ai_suggestions)
        service.search_songs
      end
    end

    context 'with invalid query' do
      let(:query) { "" }

      it 'returns validation error' do
        result = service.search_songs
        
        expect(result[:success]).to be false
        expect(result[:error]).to eq("Query must be between 2 and 100 characters")
      end
    end

    context 'when rate limited' do
      before do
        allow_any_instance_of(AiSearchService).to receive(:within_rate_limit?).and_return(false)
      end

      it 'returns rate limit error' do
        result = service.search_songs
        
        expect(result[:success]).to be false
        expect(result[:error]).to eq("Rate limit exceeded. Please try again later.")
        expect(result[:rate_limited]).to be true
      end
    end

    context 'when AI service fails' do
      before do
        allow_any_instance_of(AiSearchService).to receive(:generate_ai_suggestions).and_raise(StandardError.new("API Error"))
      end

      it 'returns fallback response' do
        result = service.search_songs
        
        expect(result[:success]).to be false
        expect(result[:error]).to eq("AI service temporarily unavailable. Please try again later.")
        expect(result[:fallback]).to be true
      end
    end
  end

  describe '#valid_query?' do
    it 'returns true for valid queries' do
      service = AiSearchService.new(query: "Beatles", user_id: user.id)
      expect(service.send(:valid_query?)).to be true
    end

    it 'returns false for empty queries' do
      service = AiSearchService.new(query: "", user_id: user.id)
      expect(service.send(:valid_query?)).to be false
    end

    it 'returns false for queries that are too short' do
      service = AiSearchService.new(query: "a", user_id: user.id)
      expect(service.send(:valid_query?)).to be false
    end

    it 'returns false for queries that are too long' do
      long_query = "a" * 101
      service = AiSearchService.new(query: long_query, user_id: user.id)
      expect(service.send(:valid_query?)).to be false
    end
  end

  describe '#within_rate_limit?' do
    it 'allows requests within rate limit' do
      service = AiSearchService.new(query: query, user_id: user.id)
      expect(service.send(:within_rate_limit?)).to be true
    end

    it 'blocks requests over rate limit' do
      service = AiSearchService.new(query: query, user_id: user.id)
      
      # Mock the cache to simulate rate limit exceeded
      allow(Rails.cache).to receive(:read).with("rate_limit:ai_search:#{user.id}").and_return(60)
      
      expect(service.send(:within_rate_limit?)).to be false
    end

    it 'allows requests without user_id' do
      service = AiSearchService.new(query: query, user_id: nil)
      expect(service.send(:within_rate_limit?)).to be true
    end
  end

  describe '#parse_ai_response' do
    let(:valid_json_response) do
      '[{"title":"Yesterday","artist":"The Beatles","album":"Help!","year":1965,"genre":"Pop","duration":"2:05","relevance_score":0.95}]'
    end

    let(:response_with_extra_text) do
      "Here are some songs: #{valid_json_response} I hope you like them!"
    end

    it 'parses valid JSON response' do
      service = AiSearchService.new(query: query, user_id: user.id)
      result = service.send(:parse_ai_response, valid_json_response)
      
      expect(result).to be_an(Array)
      expect(result.first[:title]).to eq("Yesterday")
      expect(result.first[:artist]).to eq("The Beatles")
    end

    it 'extracts JSON from response with extra text' do
      service = AiSearchService.new(query: query, user_id: user.id)
      result = service.send(:parse_ai_response, response_with_extra_text)
      
      expect(result).to be_an(Array)
      expect(result.first[:title]).to eq("Yesterday")
    end

    it 'returns empty array for invalid JSON' do
      service = AiSearchService.new(query: query, user_id: user.id)
      result = service.send(:parse_ai_response, "invalid json")
      
      expect(result).to eq([])
    end
  end
end