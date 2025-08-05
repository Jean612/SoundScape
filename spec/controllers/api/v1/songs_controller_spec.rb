require "rails_helper"

RSpec.describe Api::V1::SongsController, type: :controller do
  let(:user) { create(:user) }
  let(:token) { JwtService.encode(user_id: user.id) }

  before do
    request.headers["Authorization"] = "Bearer #{token}"
  end

  describe "GET #index" do
    let!(:song1) { create(:song, title: "Ruby Song", artist: "Rails Band") }
    let!(:song2) { create(:song, title: "JavaScript Track", artist: "Node Orchestra") }

    context "without search parameter" do
      before { get :index }

      it "returns success status" do
        expect(response).to have_http_status(:ok)
      end

      it "returns all songs" do
        json_response = JSON.parse(response.body)
        expect(json_response["songs"].length).to eq(2)
      end
    end

    context "with search parameter" do
      before { get :index, params: { search: "Ruby" } }

      it "returns filtered songs" do
        json_response = JSON.parse(response.body)
        expect(json_response["songs"].length).to eq(1)
        expect(json_response["songs"].first["title"]).to eq("Ruby Song")
      end
    end
  end

  describe "GET #show" do
    let(:song) { create(:song) }

    before { get :show, params: { id: song.id } }

    it "returns success status" do
      expect(response).to have_http_status(:ok)
    end

    it "returns song information" do
      json_response = JSON.parse(response.body)
      expect(json_response["song"]["id"]).to eq(song.id)
      expect(json_response["song"]["title"]).to eq(song.title)
      expect(json_response["song"]["artist"]).to eq(song.artist)
    end
  end

  describe "POST #create" do
    let(:valid_attributes) do
      {
        title: "New Song",
        artist: "New Artist",
        album: "New Album",
        duration_seconds: 180,
        spotify_id: "spotify123",
        youtube_id: "youtube456"
      }
    end

    context "with valid attributes" do
      before do
        post :create, params: { song: valid_attributes }
      end

      it "returns created status" do
        expect(response).to have_http_status(:created)
      end

      it "creates a new song" do
        expect(Song.count).to eq(1)
      end

      it "returns song information" do
        json_response = JSON.parse(response.body)
        expect(json_response["song"]["title"]).to eq(valid_attributes[:title])
        expect(json_response["song"]["artist"]).to eq(valid_attributes[:artist])
      end
    end

    context "with invalid attributes" do
      before do
        post :create, params: { song: { album: "No title or artist" } }
      end

      it "returns unprocessable entity status" do
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "returns validation errors" do
        json_response = JSON.parse(response.body)
        expect(json_response["errors"]).to include("Title can't be blank")
        expect(json_response["errors"]).to include("Artist can't be blank")
      end
    end
  end

  describe "PATCH #update" do
    let(:song) { create(:song, title: "Original Title") }

    context "with valid attributes" do
      before do
        patch :update, params: { id: song.id, song: { title: "Updated Title" } }
      end

      it "returns success status" do
        expect(response).to have_http_status(:ok)
      end

      it "updates the song" do
        song.reload
        expect(song.title).to eq("Updated Title")
      end

      it "returns updated song information" do
        json_response = JSON.parse(response.body)
        expect(json_response["song"]["title"]).to eq("Updated Title")
      end
    end

    context "with invalid attributes" do
      before do
        patch :update, params: { id: song.id, song: { title: "" } }
      end

      it "returns unprocessable entity status" do
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "returns validation errors" do
        json_response = JSON.parse(response.body)
        expect(json_response["errors"]).to include("Title can't be blank")
      end
    end

    context "when song does not exist" do
      it "returns not found status" do
        patch :update, params: { id: 99999, song: { title: "New Title" } }
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "DELETE #destroy" do
    let!(:song) { create(:song) }

    before { delete :destroy, params: { id: song.id } }

    it "returns no content status" do
      expect(response).to have_http_status(:no_content)
    end

    it "deletes the song" do
      expect(Song.count).to eq(0)
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
