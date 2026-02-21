Rails.application.routes.draw do
  # React frontend as root
  root "react#index"

  # Devise + ActiveAdmin
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)
  devise_for :users

  # Healthcheck
  get "up" => "rails/health#show", as: :rails_health_check

  # Chat API
  post "/chat", to: "chat#create"

  # API namespace
  namespace :api do
    resources :products, only: [:index]
  end

  # React fallback for frontend routes
  get "*path", to: "react#index", constraints: ->(req) do
    req.format.html? && !req.path.start_with?("/rails/active_storage")
  end
end