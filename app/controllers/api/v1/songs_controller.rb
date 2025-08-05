class Api::V1::SongsController < ApplicationController
  before_action :set_song, only: [ :show, :update, :destroy ]

  def index
    @songs = Song.all
    @songs = @songs.where('title ILIKE ? OR artist ILIKE ?', "%#{params[:search]}%", "%#{params[:search]}%") if params[:search].present?
    @songs = @songs.limit(20).offset((params[:page].to_i - 1) * 20) if params[:page].present?
    
    render json: {
      songs: @songs.map { |song| song_response(song) }
    }
  end

  def show
    authorize! :read, @song
    render json: {
      song: song_response(@song)
    }
  end

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

  def destroy
    authorize! :destroy, @song
    @song.destroy
    head :no_content
  end

  private

  def set_song
    @song = Song.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Song not found' }, status: :not_found
  end

  def song_params
    params.require(:song).permit(:title, :artist, :album, :duration_seconds, :spotify_id, :youtube_id)
  end

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
