# See README.md for copyright details

Rails.application.routes.draw do
  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      resources :labware_types, only: [:index, :show]
      resources :layouts,       only: [:index, :show]
      resources :labwares,      only: [:index, :show, :create, :update]
    end
  end
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
