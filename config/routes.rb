Rails.application.routes.draw do
  # Authentication routes
  get "/login", to: "sessions#new"
  post "/login", to: "sessions#create"
  delete "/logout", to: "sessions#destroy"

  # Dashboard
  get "/dashboard", to: "dashboard#index"
  root "dashboard#index"

  # API routes
  namespace :api do
    namespace :v1 do
      resources :wallets, only: [ :index, :show ] do
        member do
          get :balance
          get :transactions
        end
      end

      resources :transactions, only: [ :index, :create, :show ] do
        collection do
          post :credit
          post :debit
          post :transfer
        end
      end

      resources :users, only: [ :show ] do
        member do
          get :wallets
          get :balance
        end
      end

      resources :teams, only: [ :index, :show ] do
        member do
          get :wallets
          get :balance
        end
      end

      resources :stocks, only: [ :index, :show ] do
        member do
          get :wallets
          get :balance
          patch :update_price
        end
      end
    end
  end

  # Web interface routes (removed unused controllers)

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check

  # PWA files
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
