Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      # Authentication routes
      post 'auth/login', to: 'authentication#login'
      post 'auth/register', to: 'authentication#register'
      post 'auth/verify_otp', to: 'email_confirmations#verify_otp'
      post 'auth/resend_otp', to: 'email_confirmations#resend_otp'
      get 'auth/confirm_email', to: 'email_confirmations#confirm'
      post 'auth/resend_confirmation', to: 'email_confirmations#resend'
      
      # Resource routes
      resources :playlists do
        resources :playlist_songs, only: [:create, :destroy], path: 'songs'
      end
      
      resources :songs

      # AI Search routes
      post 'ai_search', to: 'ai_search#search'
      get 'ai_search/trending', to: 'ai_search#trending'
      get 'ai_search/history', to: 'ai_search#user_history'
      
      # AI Playlist routes - Add AI search results directly to playlists
      post 'playlists/:playlist_id/add_ai_song', to: 'ai_playlist#add_song_from_ai'
    end
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end
