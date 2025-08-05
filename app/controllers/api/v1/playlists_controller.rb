class Api::V1::PlaylistsController < ApplicationController
  before_action :set_playlist, only: [ :show, :update, :destroy ]

  def index
    @playlists = current_user[:user].playlists.includes(:songs)
    render json: {
      playlists: @playlists.map { |playlist| playlist_response(playlist) }
    }
  end

  def show
    authorize! :read, @playlist
    render json: {
      playlist: playlist_with_songs_response(@playlist)
    }
  end

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

  def destroy
    authorize! :destroy, @playlist
    @playlist.destroy
    head :no_content
  end

  private

  def set_playlist
    @playlist = Playlist.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Playlist not found' }, status: :not_found
  end

  def playlist_params
    params.require(:playlist).permit(:name, :description)
  end

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
