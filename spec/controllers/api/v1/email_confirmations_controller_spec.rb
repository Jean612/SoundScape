require "rails_helper"

RSpec.describe Api::V1::EmailConfirmationsController, type: :controller do
  describe "GET #confirm" do
    let(:user) { create(:user) }

    context "with valid token" do
      before do
        get :confirm, params: { token: user.email_confirmation_token }
      end

      it "returns success status" do
        expect(response).to have_http_status(:ok)
      end

      it "confirms user email" do
        user.reload
        expect(user.email_confirmed?).to be true
      end

      it "clears confirmation token" do
        user.reload
        expect(user.email_confirmation_token).to be_nil
      end

      it "returns success message" do
        json_response = JSON.parse(response.body)
        expect(json_response["message"]).to eq("Email confirmed successfully")
      end
    end

    context "with invalid token" do
      before do
        get :confirm, params: { token: "invalid_token" }
      end

      it "returns not found status" do
        expect(response).to have_http_status(:not_found)
      end

      it "returns error message" do
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("Invalid confirmation token")
      end
    end

    context "with already confirmed email" do
      let(:confirmed_user) { create(:user, :confirmed) }

      before do
        get :confirm, params: { token: confirmed_user.email_confirmation_token }
      end

      it "returns success status" do
        expect(response).to have_http_status(:ok)
      end

      it "returns already confirmed message" do
        json_response = JSON.parse(response.body)
        expect(json_response["message"]).to eq("Email already confirmed")
      end
    end

    context "with expired token" do
      let(:user_with_expired_token) do
        create(:user).tap do |u|
          u.update!(email_confirmation_sent_at: 25.hours.ago)
        end
      end

      before do
        get :confirm, params: { token: user_with_expired_token.email_confirmation_token }
      end

      it "returns unprocessable content status" do
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "returns expired token message" do
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("Confirmation token has expired")
      end
    end
  end

  describe "POST #resend" do
    let(:user) { create(:user) }

    context "with valid email" do
      before do
        post :resend, params: { email: user.email }
      end

      it "returns success status" do
        expect(response).to have_http_status(:ok)
      end

      it "returns success message" do
        json_response = JSON.parse(response.body)
        expect(json_response["message"]).to eq("Confirmation email sent")
      end

      it "updates confirmation sent time" do
        user.reload
        expect(user.email_confirmation_sent_at).to be_within(1.second).of(Time.current)
      end
    end

    context "with invalid email" do
      before do
        post :resend, params: { email: "nonexistent@example.com" }
      end

      it "returns not found status" do
        expect(response).to have_http_status(:not_found)
      end

      it "returns error message" do
        json_response = JSON.parse(response.body)
        expect(json_response["error"]).to eq("User not found")
      end
    end

    context "with already confirmed email" do
      let(:confirmed_user) { create(:user, :confirmed) }

      before do
        post :resend, params: { email: confirmed_user.email }
      end

      it "returns success status" do
        expect(response).to have_http_status(:ok)
      end

      it "returns already confirmed message" do
        json_response = JSON.parse(response.body)
        expect(json_response["message"]).to eq("Email already confirmed")
      end
    end
  end
end
