class Api::V1::TestController < ApplicationController
  def index
    render json: { 
      message: "API is working!", 
      environment: Rails.env,
      host: request.host,
      cors_origins: ENV['CORS_ALLOWED_ORIGINS']
    }
  end
end