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
    end
  end

  namespace :admin do
    root "dashboard#index"
    resources :users, only: %i[index show update]
    resources :posts, only: %i[index show update destroy]
    resources :tags
  end

  resources :password_resets, only: %i[new create edit update], param: :token
  
  resources :tags, only: %i[index show]

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