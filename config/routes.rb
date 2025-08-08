Rails.application.routes.draw do
  root "home#index"
  resources :posts, only: %i[new create show] do
    member do
      get :og_image
    end
  end

  resources :users, only: %i[new create show edit update]
  get 'login', to: 'user_sessions#new'
  post 'login', to: 'user_sessions#create'
  delete 'logout', to: 'user_sessions#destroy'

  get 'songs/search', to: 'songs#search', as: 'search_songs'
  
  get "up" => "rails/health#show", as: :rails_health_check
end