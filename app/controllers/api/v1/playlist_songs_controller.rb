class Api::V1::PlaylistSongsController < ApplicationController
  before_action :set_playlist
  before_action :set_playlist_song, only: [ :destroy ]

  def create
    begin
      @song = Song.find(params[:song_id])
    rescue ActiveRecord::RecordNotFound
      return render json: { error: "Song not found" }, status: :not_found
    end
    
    # Check if song already exists in playlist
    existing = @playlist.playlist_songs.find_by(song: @song)
    if existing
      return render json: { error: "Song already in playlist" }, status: :conflict
    end

    # Get next position
    next_position = @playlist.playlist_songs.maximum(:position).to_i + 1
    
    @playlist_song = @playlist.playlist_songs.build(
      song: @song,
      position: next_position
    )
    
    authorize! :create, @playlist_song
    
    if @playlist_song.save
      render json: {
        message: 'Song added to playlist',
        playlist_song: {
          id: @playlist_song.id,
          position: @playlist_song.position,
          song: song_response(@song)
        }
      }, status: :created
    else
      render json: { errors: @playlist_song.errors.full_messages }, status: :unprocessable_content
    end
  end

  def destroy
    authorize! :destroy, @playlist_song
    @playlist_song.destroy
    
    # Reorder remaining songs
    @playlist.playlist_songs.where("position > ?", @playlist_song.position)
             .update_all("position = position - 1")
    
    render json: { message: "Song removed from playlist" }
  end

  private

  def set_playlist
    @playlist = Playlist.find(params[:playlist_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Playlist not found' }, status: :not_found
  end

  def set_playlist_song
    @playlist_song = @playlist.playlist_songs.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: 'Song not found in playlist' }, status: :not_found
  end

  def song_response(song)
    {
      id: song.id,
      title: song.title,
      artist: song.artist,
      album: song.album,
      duration_seconds: song.duration_seconds
    }
  end
end
