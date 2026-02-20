Rails.application.routes.draw do
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)
  devise_for :users

  get "up" => "rails/health#show", as: :rails_health_check

  direct :rails_blob do |blob|
    route_for(:rails_blob, blob)
  end

  post "/chat", to: "chat#create"

  namespace :api do
    resources :products, only: [:index]
  end

  get "/landingpage", to: "react#index"

  get "*path", to: "react#index", constraints: lambda { |req|
    req.format.html? && !req.path.start_with?('/rails/active_storage')
  }
end
