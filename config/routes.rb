Rails.application.routes.draw do
  root "home#index"
 
  resources :posts, only: %i[new create show edit update destroy] do
    member do
      get :og_image
    end
  end

  resources :users, only: %i[new create show edit update] do
    member do 
      patch :update_avatar
      post  :playlist
    end
  end

  namespace :admin do
    root "dashboard#index"
    resources :users, only: %i[index show update]
    resources :posts, only: %i[index show update destroy]
    resources :tags
    get "spotify_bot/connect",  to: "spotify_bot#connect"
    get "spotify_bot/callback", to: "spotify_bot#callback"
  end

  namespace :auth do
    get "spotify/start",    to: "spotify#start"
    get "spotify/callback", to: "spotify#callback"   # ← Spotifyに登録したURIと完全一致
  end

  resources :tags, only: %i[index show]

  post "/me/playlist", to: "spotify_playlists#create_for_me", as: :me_playlist
  post "/tags/:id/playlist", to: "spotify_playlists#create_for_tag", as: :tag_playlist

  resources :password_resets, only: %i[new create edit update], param: :token

  get 'login', to: 'user_sessions#new'
  post 'login', to: 'user_sessions#create'
  delete 'logout', to: 'user_sessions#destroy'

  get '/terms',   to: 'static_pages#terms',   as: :terms
  get '/privacy', to: 'static_pages#privacy', as: :privacy
  get 'songs/search', to: 'songs#search', as: 'search_songs'
  
  get "up" => "rails/health#show", as: :rails_health_check

  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end
end