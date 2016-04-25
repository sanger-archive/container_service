# See README.md for copyright details

Rails.application.routes.draw do
  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      resources :labware_types, only: [:index, :show]
    end
  end
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
