require "rails_helper"

RSpec.describe Api::V1::AuthenticationController, type: :controller do
  describe "POST #login" do
    let(:user) { create(:user, :confirmed, email: "test@example.com", password: "password123") }

    context "with valid credentials" do
      before do
        post :login, params: { user: { email: user.email, password: "password123" } }
      end

      it "returns success status" do
        expect(response).to have_http_status(:ok)
      end

      it "returns JWT token" do
        json_response = JSON.parse(response.body)
        expect(json_response["token"]).to be_present
      end

      it "returns user information" do
        json_response = JSON.parse(response.body)
        expect(json_response["user"]["email"]).to eq(user.email)
        expect(json_response["user"]["name"]).to eq(user.name)
      end
    end

    context "with invalid credentials" do
      before do
        post :login, params: { user: { email: user.email, password: "wrongpassword" } }
      end

      it "returns unauthorized status" do
        expect(response).to have_http_status(:unauthorized)
      end

      it "returns error message" do
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("Invalid credentials")
      end
    end

    context "with non-existent email" do
      before do
        post :login, params: { user: { email: "nonexistent@example.com", password: "password123" } }
      end

      it "returns unauthorized status" do
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with unconfirmed email" do
      let(:unconfirmed_user) { create(:user, email: "unconfirmed@example.com", password: "password123") }

      before do
        post :login, params: { user: { email: unconfirmed_user.email, password: "password123" } }
      end

      it "returns unauthorized status" do
        expect(response).to have_http_status(:unauthorized)
      end

      it "returns email confirmation required message" do
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("Please confirm your email address before logging in")
        expect(json_response["email_confirmed"]).to be false
      end
    end
  end

  describe "POST #register" do
    let(:valid_attributes) do
      {
        email: "newuser@example.com",
        password: "password123",
        name: "New User",
        username: "newuser",
        birth_date: "1990-01-01",
        country: "USA"
      }
    end

    context "with valid attributes" do
      before do
        post :register, params: { user: valid_attributes }
      end

      it "returns created status" do
        expect(response).to have_http_status(:created)
      end

      it "creates a new user" do
        expect(User.count).to eq(1)
      end

      it "returns user information without token" do
        json_response = JSON.parse(response.body)
        expect(json_response["user"]["email"]).to eq(valid_attributes[:email])
        expect(json_response["user"]["name"]).to eq(valid_attributes[:name])
        expect(json_response["email_confirmed"]).to be false
        expect(json_response["token"]).to be_nil
      end

      it "returns confirmation message" do
        json_response = JSON.parse(response.body)
        expect(json_response["message"]).to include("Please check your email to confirm")
      end
    end

    context "with invalid attributes" do
      before do
        post :register, params: { user: { email: "invalid-email" } }
      end

      it "returns unprocessable entity status" do
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "returns validation errors" do
        json_response = JSON.parse(response.body)
        expect(json_response["errors"]).to be_present
      end

      it "does not create a user" do
        expect(User.count).to eq(0)
      end
    end

    context "with duplicate email" do
      let!(:existing_user) { create(:user, email: "test@example.com") }

      before do
        post :register, params: { user: valid_attributes.merge(email: "test@example.com") }
      end

      it "returns unprocessable entity status" do
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "returns validation errors" do
        json_response = JSON.parse(response.body)
        expect(json_response["errors"]).to include("Email has already been taken")
      end
    end
  end
end
