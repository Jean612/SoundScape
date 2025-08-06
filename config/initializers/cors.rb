# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin Ajax requests.

# Read more: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    # Simplified CORS for debugging
    if Rails.env.production?
      origins ENV['CORS_ALLOWED_ORIGINS'] || 'https://soundscape-frontend-qzwqagdi9-jean612s-projects.vercel.app'
    else
      origins 'http://localhost:3000', 'http://localhost:3001'
    end

    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      expose: ['Authorization'],
      credentials: true
  end
end
