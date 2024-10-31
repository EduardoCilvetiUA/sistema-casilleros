Rails.application.routes.draw do
  devise_for :users, controllers: {
    omniauth_callbacks: 'users/omniauth_callbacks'
  }

  # Rutas para el dashboard
  get 'dashboard', to: 'dashboard#index', as: :dashboard
  
  # Una única ruta root
  root 'home#index'
end