Rails.application.routes.draw do
  root "home#index"
  resources :posts, only: [:new, :create, :show]
  get 'songs/search', to: 'songs#search', as: 'search_songs'
  
  get "up" => "rails/health#show", as: :rails_health_check
end