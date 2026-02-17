Rails.application.routes.draw do
  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)
  devise_for :users

  # ----------------------------
  # Health & root routes
  # ----------------------------
  get "up" => "rails/health#show", as: :rails_health_check
  # root to: "home#index"

  # ----------------------------
  # Signup API with OTP
  # ----------------------------
  namespace :account_block do
    resources :accounts, only: [] do
      collection do
        post :send_otp     
        post :verify_otp   
      end
    end
  end

  post "/chat", to: "chat#create"
  get  "/chat", to: "chat#index"


end
