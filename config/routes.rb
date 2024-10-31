# config/routes.rb
Rails.application.routes.draw do
  devise_for :users, controllers: { 
    omniauth_callbacks: 'users/omniauth_callbacks'
  }

  authenticated :user do
    root 'dashboard#index', as: :authenticated_root
    
    get 'dashboard', to: 'dashboard#index'
    
    resources :controllers do
      resources :lockers do
        member do
          patch :update_password
          get :password
        end
      end
    end
    
    resources :models do
      resources :gestures, only: [:index, :create, :destroy]
    end
    
    namespace :metrics do
      get 'usage_stats'
    end
  end

  root 'home#index'
end