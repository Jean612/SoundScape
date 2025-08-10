class AiSearchService
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :query, :string
  attribute :user_id, :integer
  attribute :limit, :integer, default: 10

  CACHE_EXPIRY = 1.hour
  RATE_LIMIT_REQUESTS = 60
  RATE_LIMIT_WINDOW = 1.hour

  def initialize(attributes = {})
    super
    @api_key = ENV["OPENAI_API_KEY"]
    raise StandardError, "OPENAI_API_KEY not configured" if @api_key.blank?
  end

  def search_songs
    return rate_limit_error unless within_rate_limit?
    return validation_error unless valid_query?

    cached_result = fetch_from_cache
    return cached_result if cached_result

    begin
      track_search_analytics
      ai_response = generate_ai_suggestions
      parsed_songs = parse_ai_response(ai_response)
      cache_results(parsed_songs)

      {
        success: true,
        songs: parsed_songs,
        cached: false,
        query: query,
        timestamp: Time.current
      }
    rescue StandardError => e
      Rails.logger.error "AI Search Service Error: #{e.message}"
      fallback_response
    end
  end

  private

  def valid_query?
    query.present? && query.length >= 2 && query.length <= 100
  end

  def validation_error
    {
      success: false,
      error: "Query must be between 2 and 100 characters",
      songs: []
    }
  end

  def within_rate_limit?
    return true unless user_id

    rate_limit_cache_key = "rate_limit:ai_search:#{user_id}"
    current_requests = Rails.cache.read(rate_limit_cache_key) || 0

    if current_requests >= RATE_LIMIT_REQUESTS
      false
    else
      Rails.cache.write(rate_limit_cache_key, current_requests + 1, expires_in: RATE_LIMIT_WINDOW)
      true
    end
  end

  def rate_limit_error
    {
      success: false,
      error: "Rate limit exceeded. Please try again later.",
      songs: [],
      rate_limited: true
    }
  end

  def cache_key
    "ai_search:#{Digest::MD5.hexdigest(query.downcase.strip)}"
  end

  def fetch_from_cache
    cached_data = Rails.cache.read(cache_key)
    return nil unless cached_data

    {
      success: true,
      songs: cached_data,
      cached: true,
      query: query,
      timestamp: Time.current
    }
  end

  def generate_ai_suggestions
    prompt = build_search_prompt

    client = OpenAI::Client.new(access_token: @api_key)
    response = client.chat(
      parameters: {
        model: ENV.fetch("OPENAI_MODEL", "gpt-3.5-turbo"),
        messages: [
          { role: "user", content: prompt }
        ]
      }
    )

    response.dig("choices", 0, "message", "content") || ""
  rescue StandardError => e
    Rails.logger.error "OpenAI API Error: #{e.message}"
    raise e
  end

  def build_search_prompt
    <<~PROMPT
      You are a music recommendation AI. Based on the search query "#{query}", suggest exactly #{limit} songs that match or are related to this search.

      Please respond ONLY with a valid JSON array in this exact format:
      [
        {
          "title": "Song Title",
          "artist": "Artist Name",
          "album": "Album Name",
          "year": 2023,
          "genre": "Genre",
          "duration": "3:45",
          "relevance_score": 0.95
        }
      ]

      Rules:
      - Return exactly #{limit} songs
      - Include popular and relevant songs
      - Mix different time periods when appropriate
      - Ensure all songs are real, existing songs
      - Include relevance_score between 0.0 and 1.0
      - No additional text or explanations, just the JSON array
    PROMPT
  end

  def parse_ai_response(response)
    # Extract JSON from the response
    json_match = response.match(/\[.*\]/m)
    return [] unless json_match

    songs_data = JSON.parse(json_match[0])

    songs_data.map do |song|
      {
        title: song["title"],
        artist: song["artist"],
        album: song["album"],
        year: song["year"],
        genre: song["genre"],
        duration: song["duration"],
        relevance_score: song["relevance_score"] || 0.5
      }
    end
  rescue JSON::ParserError => e
    Rails.logger.error "Failed to parse AI response: #{e.message}"
    []
  end

  def cache_results(songs)
    Rails.cache.write(cache_key, songs, expires_in: CACHE_EXPIRY)
  end

  def track_search_analytics
    return unless user_id

    SearchAnalytic.create!(
      user_id: user_id,
      query: query,
      searched_at: Time.current,
      ip_address: nil # Will be set from controller
    )
  rescue StandardError => e
    Rails.logger.error "Failed to track search analytics: #{e.message}"
  end

  def fallback_response
    {
      success: false,
      error: "AI service temporarily unavailable. Please try again later.",
      songs: [],
      fallback: true
    }
  end
end
