Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  resources :folders, only: [ :index, :show, :new, :create, :destroy ]
  resources :photos, only: [ :index, :show, :new, :create, :destroy ]

  get "up" => "rails/health#show", as: :rails_health_check
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  root "folders#index"
end
