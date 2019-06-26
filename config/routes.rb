Rails.application.routes.draw do
  get 'home/index'
  get 'home/check'
  get 'home/results'
  resources :connected_accounts
  get 'connected_accounts/refresh'
  devise_for :users

  root 'home#index'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
