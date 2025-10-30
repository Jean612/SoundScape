# Manages the creation, retrieval, updating, and deletion of playlists.
class Api::V1::PlaylistsController < ApplicationController
  before_action :set_playlist, only: [ :show, :update, :destroy ]

  # Retrieves all playlists for the current user.
  #
  # @return [JSON] A JSON response containing the user's playlists.
  def index
    @playlists = current_user[:user].playlists.includes(:songs)
    render json: {
      playlists: @playlists.map { |playlist| playlist_response(playlist) }
    }
  end

  # Retrieves a specific playlist, including its songs.
  #
  # @param id [Integer] The ID of the playlist to retrieve.
  # @return [JSON] A JSON response containing the playlist and its songs.
  def show
    authorize! :read, @playlist
    render json: {
      playlist: playlist_with_songs_response(@playlist)
    }
  end

  # Creates a new playlist for the current user.
  #
  # @param playlist [Hash] The attributes for the new playlist.
  # @option playlist [String] :name The name of the playlist.
  # @option playlist [String] :description A description of the playlist.
  # @return [JSON] A JSON response containing the newly created playlist.
  def create
    @playlist = current_user[:user].playlists.build(playlist_params)
    authorize! :create, @playlist
    
    if @playlist.save
      render json: {
        playlist: playlist_response(@playlist)
      }, status: :created
    else
      render json: { errors: @playlist.errors.full_messages }, status: :unprocessable_content
    end
  end

  # Updates an existing playlist.
  #
  # @param id [Integer] The ID of the playlist to update.
  # @param playlist [Hash] The updated attributes for the playlist.
  # @option playlist [String] :name The new name of the playlist.
  # @option playlist [String] :description The new description of the playlist.
  # @return [JSON] A JSON response containing the updated playlist.
  def update
    authorize! :update, @playlist
    if @playlist.update(playlist_params)
      render json: {
        playlist: playlist_response(@playlist)
      }
    else
      render json: { errors: @playlist.errors.full_messages }, status: :unprocessable_content
    end
  end

  # Deletes a playlist.
  #
  # @param id [Integer] The ID of the playlist to delete.
  # @return [Head] A no-content response on successful deletion.
  def destroy
    authorize! :destroy, @playlist
    @playlist.destroy
    head :no_content
  end

  private

  # Finds the playlist based on the ID parameter.
  #
  # @return [void]
  def set_playlist
    @playlist = Playlist.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Playlist not found' }, status: :not_found
  end

  # Strong parameters for playlist creation and updates.
  #
  # @return [ActionController::Parameters] The permitted parameters.
  def playlist_params
    params.require(:playlist).permit(:name, :description)
  end

  # Formats the basic playlist data for a JSON response.
  #
  # @param playlist [Playlist] The playlist to format.
  # @return [Hash] A hash containing the playlist's data.
  def playlist_response(playlist)
    {
      id: playlist.id,
      name: playlist.name,
      description: playlist.description,
      songs_count: playlist.songs.count,
      created_at: playlist.created_at,
      updated_at: playlist.updated_at
    }
  end

  # Formats a playlist with its songs for a detailed JSON response.
  #
  # @param playlist [Playlist] The playlist to format.
  # @return [Hash] A hash containing the playlist's data and its songs.
  def playlist_with_songs_response(playlist)
    {
      id: playlist.id,
      name: playlist.name,
      description: playlist.description,
      songs: playlist.playlist_songs.includes(:song).order(:position).map do |ps|
        {
          id: ps.song.id,
          title: ps.song.title,
          artist: ps.song.artist,
          album: ps.song.album,
          duration_seconds: ps.song.duration_seconds,
          position: ps.position
        }
      end,
      created_at: playlist.created_at,
      updated_at: playlist.updated_at
    }
  end
end
