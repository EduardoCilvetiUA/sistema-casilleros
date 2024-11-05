# config/routes.rb
Rails.application.routes.draw do
  devise_for :users, controllers: { 
    omniauth_callbacks: 'users/omniauth_callbacks'
  }

  authenticated :user do
    root 'dashboard#index', as: :authenticated_root
    
    get 'dashboard', to: 'dashboard#index'
    
    resources :controllers do
      member do
        post :sync  # Agregar esta línea
      end
      resources :lockers do
        member do
          get :password
          patch :update_password
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
  namespace :mqtt do
    get 'test', to: 'test#index'
    post 'publish', to: 'test#publish'
  end

  root 'home#index'
end