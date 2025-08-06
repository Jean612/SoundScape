module Api
  module V1
    class AiPlaylistController < ApplicationController
      before_action :authorize_user!

      def add_song_from_ai
        playlist = current_user_record.playlists.find(params[:playlist_id])
        song_data = add_song_params

        # Step 1: Create or find the song
        song = find_or_create_song_from_ai_data(song_data)

        # Step 2: Add song to playlist (avoid duplicates)
        playlist_song = playlist.playlist_songs.find_by(song: song)
        
        if playlist_song
          render json: {
            success: true,
            message: "Song already in playlist",
            playlist_song: format_playlist_song(playlist_song),
            action: "existing"
          }, status: :ok
        else
          position = playlist.playlist_songs.maximum(:position).to_i + 1
          playlist_song = playlist.playlist_songs.create!(
            song: song,
            position: position
          )

          render json: {
            success: true,
            message: "Song added to playlist successfully",
            playlist_song: format_playlist_song(playlist_song),
            action: "added"
          }, status: :created
        end

      rescue ActiveRecord::RecordNotFound
        render json: { 
          success: false, 
          error: "Playlist not found" 
        }, status: :not_found
      rescue ActiveRecord::RecordInvalid => e
        render json: { 
          success: false, 
          error: e.record.errors.full_messages.join(", ") 
        }, status: :unprocessable_content
      rescue StandardError => e
        Rails.logger.error "Add song from AI error: #{e.message}"
        render json: { 
          success: false, 
          error: "Failed to add song to playlist" 
        }, status: :internal_server_error
      end

      private

      def add_song_params
        params.require(:song).permit(
          :title, :artist, :album, :year, :genre, :duration, :relevance_score
        )
      end

      def find_or_create_song_from_ai_data(song_data)
        # Try to find existing song first (avoid duplicates)
        existing_song = Song.find_by(
          title: song_data[:title],
          artist: song_data[:artist]
        )

        return existing_song if existing_song

        # Create new song from AI data
        duration_seconds = parse_duration_to_seconds(song_data[:duration])
        
        Song.create!(
          title: song_data[:title],
          artist: song_data[:artist],
          album: song_data[:album],
          duration_seconds: duration_seconds
        )
      end

      def parse_duration_to_seconds(duration_string)
        return 0 if duration_string.blank?
        
        # Parse formats like "3:45" or "2:30"
        parts = duration_string.split(":")
        return 0 if parts.length != 2
        
        minutes = parts[0].to_i
        seconds = parts[1].to_i
        (minutes * 60) + seconds
      rescue StandardError
        0
      end

      def format_playlist_song(playlist_song)
        {
          id: playlist_song.id,
          position: playlist_song.position,
          song: {
            id: playlist_song.song.id,
            title: playlist_song.song.title,
            artist: playlist_song.song.artist,
            album: playlist_song.song.album,
            duration_seconds: playlist_song.song.duration_seconds
          }
        }
      end

      def authorize_user!
        return render json: { error: "Access denied" }, status: :forbidden unless current_user&.dig(:user)&.email_confirmed?
      end

      def current_user_record
        @current_user_record ||= current_user&.dig(:user)
      end
    end
  end
end