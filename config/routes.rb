Rails.application.routes.draw do
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)

  get "up" => "rails/health#show", as: :rails_health_check

  # Chat API
  post "/chat", to: "chat#create"

  # Products API
  namespace :api do
    resources :products, only: [:index]
  end
end