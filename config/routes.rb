Rails.application.routes.draw do
  resources :segments
  get "dashboard", to: "dashboard#index"
  namespace :api do
    namespace :v1 do
      resources :announcements, only: %i[index show] do
        member do
          post :read
        end
      end
    end
  end
  resource :session
  resources :passwords, param: :token

  resources :contacts, only: %i[index show destroy]
  resources :announcements
  resources :tickets

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", :as => :rails_health_check

  get "script.js", to: "welcome#script"

  # Defines the root path route ("/")
  root "welcome#home"
end
