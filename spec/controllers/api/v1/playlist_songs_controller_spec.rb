require "rails_helper"

RSpec.describe Api::V1::PlaylistSongsController, type: :controller do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:token) { JwtService.encode(user_id: user.id) }
  let(:playlist) { create(:playlist, user: user) }
  let(:other_playlist) { create(:playlist, user: other_user) }
  let(:song) { create(:song) }

  before do
    request.headers["Authorization"] = "Bearer #{token}"
  end

  describe "POST #create" do
    context "when adding song to user's own playlist" do
      before do
        post :create, params: { playlist_id: playlist.id, song_id: song.id }
      end

      it "returns created status" do
        expect(response).to have_http_status(:created)
      end

      it "adds song to playlist" do
        expect(playlist.songs.count).to eq(1)
        expect(playlist.songs.first).to eq(song)
      end

      it "sets correct position" do
        expect(playlist.playlist_songs.first.position).to eq(1)
      end

      it "returns playlist song information" do
        json_response = JSON.parse(response.body)
        expect(json_response["playlist_song"]["song"]["id"]).to eq(song.id)
        expect(json_response["playlist_song"]["position"]).to eq(1)
      end
    end

    context "when adding multiple songs" do
      let(:song2) { create(:song) }

      before do
        post :create, params: { playlist_id: playlist.id, song_id: song.id }
        post :create, params: { playlist_id: playlist.id, song_id: song2.id }
      end

      it "assigns correct positions" do
        positions = playlist.playlist_songs.pluck(:position).sort
        expect(positions).to eq([ 1, 2 ])
      end
    end

    context "when adding duplicate song" do
      before do
        create(:playlist_song, playlist: playlist, song: song, position: 1)
        post :create, params: { playlist_id: playlist.id, song_id: song.id }
      end

      it "returns conflict status" do
        expect(response).to have_http_status(:conflict)
      end

      it "returns error message" do
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("Song already in playlist")
      end

      it "does not add duplicate song" do
        expect(playlist.songs.count).to eq(1)
      end
    end

    context "when trying to add song to another user's playlist" do
      it "returns forbidden status" do
        post :create, params: { playlist_id: other_playlist.id, song_id: song.id }
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when song does not exist" do
      it "returns not found status" do
        post :create, params: { playlist_id: playlist.id, song_id: 99999 }
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "DELETE #destroy" do
    let!(:playlist_song1) { create(:playlist_song, playlist: playlist, song: song, position: 1) }
    let!(:song2) { create(:song) }
    let!(:playlist_song2) { create(:playlist_song, playlist: playlist, song: song2, position: 2) }
    let!(:song3) { create(:song) }
    let!(:playlist_song3) { create(:playlist_song, playlist: playlist, song: song3, position: 3) }

    context "when removing song from user's own playlist" do
      before do
        delete :destroy, params: { playlist_id: playlist.id, id: playlist_song2.id }
      end

      it "returns success status" do
        expect(response).to have_http_status(:ok)
      end

      it "removes song from playlist" do
        expect(playlist.songs.count).to eq(2)
        expect(playlist.songs).not_to include(song2)
      end

      it "reorders remaining songs" do
        playlist.reload
        positions = playlist.playlist_songs.order(:position).pluck(:position)
        expect(positions).to eq([ 1, 2 ])
      end

      it "returns success message" do
        json_response = JSON.parse(response.body)
        expect(json_response["message"]).to eq("Song removed from playlist")
      end
    end

    context "when trying to remove song from another user's playlist" do
      let(:other_playlist_song) { create(:playlist_song, playlist: other_playlist, song: song, position: 1) }

      it "returns forbidden status" do
        delete :destroy, params: { playlist_id: other_playlist.id, id: other_playlist_song.id }
        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when playlist song does not exist" do
      it "returns not found status" do
        delete :destroy, params: { playlist_id: playlist.id, id: 99999 }
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  context "without authentication token" do
    before do
      request.headers["Authorization"] = nil
    end

    it "returns unauthorized status for create" do
      post :create, params: { playlist_id: playlist.id, song_id: song.id }
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns unauthorized status for destroy" do
      playlist_song = create(:playlist_song, playlist: playlist, song: song, position: 1)
      delete :destroy, params: { playlist_id: playlist.id, id: playlist_song.id }
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
