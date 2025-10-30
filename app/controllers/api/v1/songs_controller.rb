# Manages the CRUD operations for songs.
class Api::V1::SongsController < ApplicationController
  before_action :set_song, only: [ :show, :update, :destroy ]

  # Retrieves a list of songs, with optional search and pagination.
  #
  # @param search [String] A search term to filter songs by title or artist.
  # @param page [Integer] The page number for pagination.
  # @return [JSON] A JSON response containing the list of songs.
  def index
    @songs = Song.all
    @songs = @songs.where('title ILIKE ? OR artist ILIKE ?', "%#{params[:search]}%", "%#{params[:search]}%") if params[:search].present?
    @songs = @songs.limit(20).offset((params[:page].to_i - 1) * 20) if params[:page].present?
    
    render json: {
      songs: @songs.map { |song| song_response(song) }
    }
  end

  # Retrieves a specific song.
  #
  # @param id [Integer] The ID of the song to retrieve.
  # @return [JSON] A JSON response containing the song's data.
  def show
    authorize! :read, @song
    render json: {
      song: song_response(@song)
    }
  end

  # Creates a new song.
  #
  # @param song [Hash] The attributes for the new song.
  # @option song [String] :title The title of the song.
  # @option song [String] :artist The artist of the song.
  # @option song [String] :album The album of the song.
  # @option song [Integer] :duration_seconds The duration of the song in seconds.
  # @option song [String] :spotify_id The Spotify ID of the song.
  # @option song [String] :youtube_id The YouTube ID of the song.
  # @return [JSON] A JSON response containing the newly created song.
  def create
    @song = Song.new(song_params)
    authorize! :create, @song
    
    if @song.save
      render json: {
        song: song_response(@song)
      }, status: :created
    else
      render json: { errors: @song.errors.full_messages }, status: :unprocessable_content
    end
  end

  # Updates an existing song.
  #
  # @param id [Integer] The ID of the song to update.
  # @param song [Hash] The updated attributes for the song.
  # @return [JSON] A JSON response containing the updated song.
  def update
    authorize! :update, @song
    if @song.update(song_params)
      render json: {
        song: song_response(@song)
      }
    else
      render json: { errors: @song.errors.full_messages }, status: :unprocessable_content
    end
  end

  # Deletes a song.
  #
  # @param id [Integer] The ID of the song to delete.
  # @return [Head] A no-content response on successful deletion.
  def destroy
    authorize! :destroy, @song
    @song.destroy
    head :no_content
  end

  private

  # Finds the song based on the ID parameter.
  #
  # @return [void]
  def set_song
    @song = Song.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Song not found' }, status: :not_found
  end

  # Strong parameters for song creation and updates.
  #
  # @return [ActionController::Parameters] The permitted parameters.
  def song_params
    params.require(:song).permit(:title, :artist, :album, :duration_seconds, :spotify_id, :youtube_id)
  end

  # Formats the song data for a JSON response.
  #
  # @param song [Song] The song to format.
  # @return [Hash] A hash containing the song's data.
  def song_response(song)
    {
      id: song.id,
      title: song.title,
      artist: song.artist,
      album: song.album,
      duration_seconds: song.duration_seconds,
      spotify_id: song.spotify_id,
      youtube_id: song.youtube_id,
      created_at: song.created_at
    }
  end
end
