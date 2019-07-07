# == Route Map
#
#                     Prefix Verb   URI Pattern                                                                              Controller#Action
#               transactions POST   /transactions(.:format)                                                                  transactions#create
#            new_transaction GET    /transactions/new(.:format)                                                              transactions#new
#                transaction PATCH  /transactions/:id(.:format)                                                              transactions#update
#                            PUT    /transactions/:id(.:format)                                                              transactions#update
# connected_accounts_refresh GET    /connected_accounts/refresh(.:format)                                                    connected_accounts#refresh
#     connected_accounts_add GET    /connected_accounts/add(.:format)                                                        connected_accounts#add
#         connected_accounts GET    /connected_accounts(.:format)                                                            connected_accounts#index
#                            POST   /connected_accounts(.:format)                                                            connected_accounts#create
#     edit_connected_account GET    /connected_accounts/:id/edit(.:format)                                                   connected_accounts#edit
#          connected_account PATCH  /connected_accounts/:id(.:format)                                                        connected_accounts#update
#                            PUT    /connected_accounts/:id(.:format)                                                        connected_accounts#update
#                            DELETE /connected_accounts/:id(.:format)                                                        connected_accounts#destroy
#           new_user_session GET    /users/sign_in(.:format)                                                                 devise/sessions#new
#               user_session POST   /users/sign_in(.:format)                                                                 devise/sessions#create
#       destroy_user_session DELETE /users/sign_out(.:format)                                                                devise/sessions#destroy
#          new_user_password GET    /users/password/new(.:format)                                                            devise/passwords#new
#         edit_user_password GET    /users/password/edit(.:format)                                                           devise/passwords#edit
#              user_password PATCH  /users/password(.:format)                                                                devise/passwords#update
#                            PUT    /users/password(.:format)                                                                devise/passwords#update
#                            POST   /users/password(.:format)                                                                devise/passwords#create
#   cancel_user_registration GET    /users/cancel(.:format)                                                                  devise/registrations#cancel
#      new_user_registration GET    /users/sign_up(.:format)                                                                 devise/registrations#new
#     edit_user_registration GET    /users/edit(.:format)                                                                    devise/registrations#edit
#          user_registration PATCH  /users(.:format)                                                                         devise/registrations#update
#                            PUT    /users(.:format)                                                                         devise/registrations#update
#                            DELETE /users(.:format)                                                                         devise/registrations#destroy
#                            POST   /users(.:format)                                                                         devise/registrations#create
#                       root GET    /                                                                                        connected_accounts#index
#         rails_service_blob GET    /rails/active_storage/blobs/:signed_id/*filename(.:format)                               active_storage/blobs#show
#  rails_blob_representation GET    /rails/active_storage/representations/:signed_blob_id/:variation_key/*filename(.:format) active_storage/representations#show
#         rails_disk_service GET    /rails/active_storage/disk/:encoded_key/*filename(.:format)                              active_storage/disk#show
#  update_rails_disk_service PUT    /rails/active_storage/disk/:encoded_token(.:format)                                      active_storage/disk#update
#       rails_direct_uploads POST   /rails/active_storage/direct_uploads(.:format)                                           active_storage/direct_uploads#create

Rails.application.routes.draw do
  resources :transactions, except: [:show, :edit, :index, :destroy, :update]
  # post 'transactions/stripe_webhooks'
  get 'connected_accounts/refresh'
  get 'connected_accounts/add'
  resources :connected_accounts, except: [:show, :new]
  devise_for :users

  mount StripeEvent::Engine, at: '/stripe_webhooks'

  root 'connected_accounts#index'
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
