require 'rails_helper'

RSpec.describe Api::V1::AiPlaylistController, type: :controller do
  let(:user) { create(:user, email_confirmed: true) }
  let(:token) { JwtService.encode(user_id: user.id) }
  let(:playlist) { create(:playlist, user: user) }
  let(:song_data) do
    {
      title: "Bohemian Rhapsody",
      artist: "Queen",
      album: "A Night at the Opera",
      year: 1975,
      genre: "Rock",
      duration: "5:55",
      relevance_score: 0.98
    }
  end

  before do
    request.headers["Authorization"] = "Bearer #{token}"
  end

  describe 'POST #add_song_from_ai' do
    context 'with valid parameters' do
      it 'creates a new song and adds it to the playlist' do
        expect {
          post :add_song_from_ai, params: { playlist_id: playlist.id, song: song_data }
        }.to change(Song, :count).by(1)
          .and change(PlaylistSong, :count).by(1)

        expect(response).to have_http_status(:created)
        
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be true
        expect(json_response['action']).to eq('added')
        expect(json_response['message']).to eq('Song added to playlist successfully')
      end

      it 'calculates duration_seconds correctly' do
        post :add_song_from_ai, params: { playlist_id: playlist.id, song: song_data }
        
        song = Song.last
        expect(song.duration_seconds).to eq(355) # 5:55 = 355 seconds
      end

      it 'sets correct position in playlist' do
        # Add an existing song to test position calculation
        existing_song = create(:song)
        create(:playlist_song, playlist: playlist, song: existing_song, position: 1)

        post :add_song_from_ai, params: { playlist_id: playlist.id, song: song_data }

        json_response = JSON.parse(response.body)
        expect(json_response['playlist_song']['position']).to eq(2)
      end
    end

    context 'when song already exists' do
      let!(:existing_song) { create(:song, title: song_data[:title], artist: song_data[:artist]) }

      it 'uses existing song instead of creating a new one' do
        expect {
          post :add_song_from_ai, params: { playlist_id: playlist.id, song: song_data }
        }.to change(Song, :count).by(0)
          .and change(PlaylistSong, :count).by(1)

        expect(response).to have_http_status(:created)
      end
    end

    context 'when song is already in playlist' do
      let!(:existing_song) { create(:song, title: song_data[:title], artist: song_data[:artist]) }
      let!(:playlist_song) { create(:playlist_song, playlist: playlist, song: existing_song) }

      it 'returns existing playlist song without creating duplicate' do
        expect {
          post :add_song_from_ai, params: { playlist_id: playlist.id, song: song_data }
        }.to change(Song, :count).by(0)
          .and change(PlaylistSong, :count).by(0)

        expect(response).to have_http_status(:ok)
        
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be true
        expect(json_response['action']).to eq('existing')
        expect(json_response['message']).to eq('Song already in playlist')
      end
    end

    context 'with invalid playlist_id' do
      it 'returns not found error' do
        post :add_song_from_ai, params: { playlist_id: 99999, song: song_data }

        expect(response).to have_http_status(:not_found)
        
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be false
        expect(json_response['error']).to eq('Playlist not found')
      end
    end

    context 'with invalid song data' do
      it 'returns validation error' do
        invalid_song_data = song_data.merge(title: nil)
        
        post :add_song_from_ai, params: { playlist_id: playlist.id, song: invalid_song_data }

        expect(response).to have_http_status(:unprocessable_content)
        
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be false
        expect(json_response['error']).to include("can't be blank")
      end
    end
  end

  describe 'private methods' do
    let(:controller_instance) { described_class.new }

    describe '#parse_duration_to_seconds' do
      it 'parses standard duration format correctly' do
        expect(controller_instance.send(:parse_duration_to_seconds, "3:45")).to eq(225)
        expect(controller_instance.send(:parse_duration_to_seconds, "0:30")).to eq(30)
        expect(controller_instance.send(:parse_duration_to_seconds, "10:15")).to eq(615)
      end

      it 'handles invalid formats gracefully' do
        expect(controller_instance.send(:parse_duration_to_seconds, "invalid")).to eq(0)
        expect(controller_instance.send(:parse_duration_to_seconds, nil)).to eq(0)
        expect(controller_instance.send(:parse_duration_to_seconds, "")).to eq(0)
        expect(controller_instance.send(:parse_duration_to_seconds, "3:45:30")).to eq(0)
      end
    end
  end
end