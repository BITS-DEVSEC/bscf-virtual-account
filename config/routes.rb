Rails.application.routes.draw do
  resources :listings

  resources :virtual_account_transactions
  resources :virtual_accounts do
    collection do
      get :verified_accounts
      get :my_virtual_accounts
      get :lookup_by_account_number
    end
    member do
      put :approve
      put :suspend
    end
  end
  
  get "up" => "rails/health#show", as: :rails_health_check
end
