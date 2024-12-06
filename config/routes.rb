Rails.application.routes.draw do
  get "dashboard", to: "dashboard#index"
  namespace :api do
    namespace :v1 do
      # Your API endpoints
      resources :announcements
      # other resources...
    end
  end
  resource :session
  resources :passwords, param: :token
  resources :announcements
  resources :tickets
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", :as => :rails_health_check

  get "script.js", to: "welcome#script"

  # Defines the root path route ("/")
  root "welcome#home"
end
