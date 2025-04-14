Rails.application.routes.draw do
  resources :listings

  resources :virtual_account_transactions
  resources :virtual_accounts do
    collection do
      get :verified_accounts
    end
    member do
      patch :update_kyc_status
    end
  end
  
  get "up" => "rails/health#show", as: :rails_health_check
end
