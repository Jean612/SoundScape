require 'rails_helper'

RSpec.describe JwtService, type: :service do
  let(:payload) { { user_id: 1 } }

  describe '.encode' do
    it 'genera un token JWT válido' do
      token = described_class.encode(payload)
      expect(token).to be_a(String)
      decoded = JWT.decode(token, Rails.application.secret_key_base)[0]
      expect(decoded['user_id']).to eq(payload[:user_id])
      expect(decoded).to have_key('exp')
    end
  end

  describe '.decode' do
    it 'recupera el payload original' do
      token = described_class.encode(payload)
      decoded_payload = described_class.decode(token)
      expect(decoded_payload[:user_id]).to eq(payload[:user_id])
    end

    it 'lanza una excepción legible ante tokens inválidos' do
      expect { described_class.decode('token.invalido') }.to raise_error(StandardError, /Invalid token/)
    end
  end
end
