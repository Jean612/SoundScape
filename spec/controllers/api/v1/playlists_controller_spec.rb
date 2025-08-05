require "rails_helper"

RSpec.describe Api::V1::PlaylistsController, type: :controller do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:token) { JwtService.encode(user_id: user.id) }
  let(:other_token) { JwtService.encode(user_id: other_user.id) }

  before do
    request.headers["Authorization"] = "Bearer #{token}"
  end

  describe "GET #index" do
    let!(:user_playlist) { create(:playlist, user: user) }
    let!(:other_playlist) { create(:playlist, user: other_user) }

    before { get :index }

    it "returns success status" do
      expect(response).to have_http_status(:ok)
    end

    it "returns only current user's playlists" do
      json_response = JSON.parse(response.body)
      expect(json_response["playlists"].length).to eq(1)
      expect(json_response["playlists"].first["id"]).to eq(user_playlist.id)
    end
  end

  describe "GET #show" do
    let(:playlist) { create(:playlist, user: user) }
    let!(:song) { create(:song) }
    let!(:playlist_song) { create(:playlist_song, playlist: playlist, song: song, position: 1) }

    context "when playlist belongs to current user" do
      before { get :show, params: { id: playlist.id } }

      it "returns success status" do
        expect(response).to have_http_status(:ok)
      end

      it "returns playlist with songs" do
        json_response = JSON.parse(response.body)
        expect(json_response["playlist"]["id"]).to eq(playlist.id)
        expect(json_response["playlist"]["songs"].length).to eq(1)
        expect(json_response["playlist"]["songs"].first["title"]).to eq(song.title)
      end
    end

    context "when playlist belongs to another user" do
      let(:other_playlist) { create(:playlist, user: other_user) }

      it "returns forbidden status" do
        get :show, params: { id: other_playlist.id }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "POST #create" do
    let(:valid_attributes) { { name: "My Playlist", description: "Test playlist" } }

    context "with valid attributes" do
      before do
        post :create, params: { playlist: valid_attributes }
      end

      it "returns created status" do
        expect(response).to have_http_status(:created)
      end

      it "creates a new playlist" do
        expect(user.playlists.count).to eq(1)
      end

      it "returns playlist information" do
        json_response = JSON.parse(response.body)
        expect(json_response["playlist"]["name"]).to eq(valid_attributes[:name])
        expect(json_response["playlist"]["description"]).to eq(valid_attributes[:description])
      end
    end

    context "with invalid attributes" do
      before do
        post :create, params: { playlist: { description: "No name" } }
      end

      it "returns unprocessable entity status" do
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "returns validation errors" do
        json_response = JSON.parse(response.body)
        expect(json_response["errors"]).to include("Name can't be blank")
      end
    end
  end

  describe "PATCH #update" do
    let(:playlist) { create(:playlist, user: user, name: "Original Name") }

    context "with valid attributes" do
      before do
        patch :update, params: { id: playlist.id, playlist: { name: "Updated Name" } }
      end

      it "returns success status" do
        expect(response).to have_http_status(:ok)
      end

      it "updates the playlist" do
        playlist.reload
        expect(playlist.name).to eq("Updated Name")
      end

      it "returns updated playlist information" do
        json_response = JSON.parse(response.body)
        expect(json_response["playlist"]["name"]).to eq("Updated Name")
      end
    end

    context "when playlist belongs to another user" do
      let(:other_playlist) { create(:playlist, user: other_user) }

      it "returns forbidden status" do
        patch :update, params: { id: other_playlist.id, playlist: { name: "Hacked" } }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "DELETE #destroy" do
    let!(:playlist) { create(:playlist, user: user) }

    context "when playlist belongs to current user" do
      before { delete :destroy, params: { id: playlist.id } }

      it "returns no content status" do
        expect(response).to have_http_status(:no_content)
      end

      it "deletes the playlist" do
        expect(user.playlists.count).to eq(0)
      end
    end

    context "when playlist belongs to another user" do
      let(:other_playlist) { create(:playlist, user: other_user) }

      it "returns forbidden status" do
        delete :destroy, params: { id: other_playlist.id }
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  context "without authentication token" do
    before do
      request.headers["Authorization"] = nil
    end

    it "returns unauthorized status" do
      get :index
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
