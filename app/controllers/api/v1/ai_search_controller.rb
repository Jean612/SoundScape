module Api
  module V1
    class AiSearchController < ApplicationController
      before_action :authorize_user!

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
          error: "Search service temporarily unavailable"
        }, status: :service_unavailable
      end

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
          error: "Unable to fetch trending searches"
        }, status: :service_unavailable
      end

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

      def search_params
        params.require(:search).permit(:query, :limit)
      rescue ActionController::ParameterMissing
        params.permit(:query, :limit)
      end

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

      def authorize_user!
        return render json: { error: 'Access denied' }, status: :forbidden unless current_user&.dig(:user)&.email_confirmed?
      end

      def current_user_record
        @current_user_record ||= current_user&.dig(:user)
      end
    end
  end
end