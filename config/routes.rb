Rails.application.routes.draw do
  devise_for :users, controllers: {
    omniauth_callbacks: "users/omniauth_callbacks"
  }

  # Rutas para superusuarios
  authenticated :user, ->(user) { user.is_superuser? } do
    root "dashboard#index", as: :superuser_root
  end

  # Rutas para usuarios normales autenticados
  authenticated :user do
    root "controllers#index", as: :authenticated_root

    get "dashboard", to: "dashboard#index"
    resources :controllers do
      member do
        post :sync
      end
      resources :lockers do
        member do
          get :password
          patch :update_password
          post :update_owner
        end
      end
    end

    # config/routes.rb
    resources :users do
      member do
        patch :update_model
      end
    end

    resources :models do
      member do
        get :gestos
      end
    end

    namespace :metrics do
      get "usage_stats"
    end
  end

  namespace :mqtt do
    get "test", to: "test#index"
    post "publish", to: "test#publish"
  end

  root "home#index"
end
