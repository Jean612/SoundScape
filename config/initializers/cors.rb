# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Handle Cross-Origin Resource Sharing (CORS) in order to accept cross-origin Ajax requests.

# Read more: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    if Rails.env.development?
      # Allow all origins in development only
      origins '*'
      resource '*',
        headers: :any,
        methods: [:get, :post, :put, :patch, :delete, :options, :head],
        expose: ['Authorization'],
        credentials: true
    else
      # Production: Use environment variable or safe defaults
      allowed_origins = if ENV['CORS_ALLOWED_ORIGINS'].present?
        ENV['CORS_ALLOWED_ORIGINS'].split(',').map(&:strip)
      else
        [
          'https://soundscape-frontend-qzwqagdi9-jean612s-projects.vercel.app'
        ]
      end

      origins allowed_origins
      resource '*',
        headers: :any,
        methods: [:get, :post, :put, :patch, :delete, :options, :head],
        expose: ['Authorization'],
        credentials: true
    end
  end
end
