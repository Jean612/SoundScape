module Api
  module V1
    # Handles AI-powered song searches, trending searches, and user search history.
    class AiSearchController < ApplicationController
      before_action :authorize_user!

      # Performs a song search using the AI Search Service.
      #
      # @param search [Hash] The search parameters.
      # @option search [String] :query The search query.
      # @option search [Integer] :limit The maximum number of results to return.
      # @return [JSON] A JSON response with the search results or an error message.
      def search
        search_service = AiSearchService.new(
          query: search_params[:query],
          user_id: current_user_record.id,
          limit: search_params[:limit]&.to_i || 10
        )

        result = search_service.search_songs

        if result[:success]
          track_search_analytics(result)
          render json: {
            success: true,
            data: {
              songs: result[:songs],
              query: result[:query],
              cached: result[:cached] || false,
              results_count: result[:songs].length,
              timestamp: result[:timestamp]
            }
          }, status: :ok
        else
          render json: {
            success: false,
            error: result[:error],
            rate_limited: result[:rate_limited] || false
          }, status: result[:rate_limited] ? :too_many_requests : :unprocessable_content
        end
      rescue StandardError => e
        Rails.logger.error "AI Search Controller Error: #{e.message}"
        render json: {
          success: false,
          error: 'Search service temporarily unavailable'
        }, status: :service_unavailable
      end

      # Retrieves trending search queries.
      #
      # @param limit [Integer] The maximum number of trending searches to return (default: 10).
      # @param time_period [Integer] The time period in hours to consider for trending searches (default: 24).
      # @return [JSON] A JSON response with the trending searches or an error message.
      def trending
        trending_searches = SearchAnalytic.trending_searches(
          limit: params[:limit]&.to_i || 10,
          time_period: (params[:time_period]&.to_i || 24).hours
        )

        render json: {
          success: true,
          data: {
            trending_searches: trending_searches,
            time_period_hours: params[:time_period]&.to_i || 24
          }
        }, status: :ok
      rescue StandardError => e
        Rails.logger.error "Trending Search Error: #{e.message}"
        render json: {
          success: false,
          error: 'Unable to fetch trending searches'
        }, status: :service_unavailable
      end

      # Retrieves the current user's search history with pagination.
      #
      # @param page [Integer] The page number for pagination (default: 1).
      # @param per_page [Integer] The number of results per page (default: 20, max: 100).
      # @return [JSON] A JSON response with the user's search history.
      def user_history
        page = params[:page]&.to_i || 1
        per_page = [params[:per_page]&.to_i || 20, 100].min

        searches = SearchAnalytic
                   .by_user(current_user_record.id)
                   .recent
                   .limit(per_page)
                   .offset((page - 1) * per_page)

        render json: {
          success: true,
          data: {
            searches: searches.map do |search|
              {
                id: search.id,
                query: search.query,
                searched_at: search.searched_at,
                results_count: search.results_count
              }
            end,
            pagination: {
              page: page,
              per_page: per_page,
              total_count: SearchAnalytic.by_user(current_user_record.id).count
            }
          }
        }, status: :ok
      end

      private

      # Strong parameters for the search action.
      #
      # @return [ActionController::Parameters] The permitted parameters.
      def search_params
        params.require(:search).permit(:query, :limit)
      rescue ActionController::ParameterMissing
        params.permit(:query, :limit)
      end

      # Tracks the search analytics if the search was successful and not cached.
      #
      # @param result [Hash] The result from the AI Search Service.
      # @return [void]
      def track_search_analytics(result)
        return unless result[:success] && !result[:cached]

        SearchAnalytic.create!(
          user_id: current_user_record.id,
          query: result[:query],
          searched_at: Time.current,
          ip_address: request.remote_ip,
          results_count: result[:songs].length
        )
      rescue StandardError => e
        Rails.logger.error "Failed to track search analytics: #{e.message}"
      end

      # Ensures the user is authorized to perform the action.
      #
      # @return [void]
      def authorize_user!
        return render json: { error: 'Access denied' }, status: :forbidden unless current_user&.dig(:user)&.email_confirmed?
      end

      # Gets the current user record.
      #
      # @return [User] The current user record.
      def current_user_record
        @current_user_record ||= current_user&.dig(:user)
      end
    end
  end
end