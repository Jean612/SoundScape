module Api
  module V1
    # Manages adding songs suggested by AI to a user's playlist.
    class AiPlaylistController < ApplicationController
      before_action :authorize_user!

      # Adds a song to a playlist based on AI-generated data.
      # If the song already exists in the database, it's reused.
      # If the song is already in the playlist, it returns the existing entry.
      # Otherwise, it creates the song and adds it to the playlist.
      #
      # @param :playlist_id [Integer] The ID of the playlist.
      # @param :song [Hash] A hash containing the song's attributes.
      # @option :song [String] :title The title of the song.
      # @option :song [String] :artist The artist of the song.
      # @option :song [String] :album The album of the song.
      # @option :song [String] :duration The duration of the song in "MM:SS" format.
      # @return [JSON] A JSON response indicating success or failure.
      def add_song_from_ai
        playlist = current_user_record.playlists.find(params[:playlist_id])
        song_data = add_song_params

        song = find_or_create_song_from_ai_data(song_data)

        playlist_song = playlist.playlist_songs.find_by(song: song)

        if playlist_song
          render json: {
            success: true,
            message: 'Song already in playlist',
            playlist_song: format_playlist_song(playlist_song),
            action: 'existing'
          }, status: :ok
        else
          position = playlist.playlist_songs.maximum(:position).to_i + 1
          playlist_song = playlist.playlist_songs.create!(
            song: song,
            position: position
          )

          render json: {
            success: true,
            message: 'Song added to playlist successfully',
            playlist_song: format_playlist_song(playlist_song),
            action: 'added'
          }, status: :created
        end
      rescue ActiveRecord::RecordNotFound
        render json: {
          success: false,
          error: 'Playlist not found'
        }, status: :not_found
      rescue ActiveRecord::RecordInvalid => e
        render json: {
          success: false,
          error: e.record.errors.full_messages.join(', ')
        }, status: :unprocessable_content
      rescue StandardError => e
        Rails.logger.error "Add song from AI error: #{e.message}"
        render json: {
          success: false,
          error: 'Failed to add song to playlist'
        }, status: :internal_server_error
      end

      private

      # Strong parameters for adding a song from AI.
      #
      # @return [ActionController::Parameters] The permitted parameters.
      def add_song_params
        params.require(:song).permit(
          :title, :artist, :album, :year, :genre, :duration, :relevance_score
        )
      end

      # Finds an existing song or creates a new one from AI data.
      #
      # @param song_data [Hash] The song's attributes.
      # @return [Song] The found or created song record.
      def find_or_create_song_from_ai_data(song_data)
        existing_song = Song.find_by(
          title: song_data[:title],
          artist: song_data[:artist]
        )

        return existing_song if existing_song

        duration_seconds = parse_duration_to_seconds(song_data[:duration])

        Song.create!(
          title: song_data[:title],
          artist: song_data[:artist],
          album: song_data[:album],
          duration_seconds: duration_seconds
        )
      end

      # Parses a duration string (e.g., "3:45") into seconds.
      #
      # @param duration_string [String] The duration in "MM:SS" format.
      # @return [Integer] The duration in seconds.
      def parse_duration_to_seconds(duration_string)
        return 0 if duration_string.blank?

        parts = duration_string.split(':')
        return 0 if parts.length != 2

        minutes = parts[0].to_i
        seconds = parts[1].to_i
        (minutes * 60) + seconds
      rescue StandardError
        0
      end

      # Formats the playlist song for the JSON response.
      #
      # @param playlist_song [PlaylistSong] The playlist song record.
      # @return [Hash] The formatted hash.
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