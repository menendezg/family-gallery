Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  resources :photos, only: [ :index, :show, :new, :create, :destroy ]

  get "up" => "rails/health#show", as: :rails_health_check

  root "photos#index"
end
