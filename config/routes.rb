Rails.application.routes.draw do
  get "dashboard", to: "dashboard#index"

  namespace :api do
    namespace :v1 do
      post "identity", to: "identity#create"

      resources :announcements, only: %i[index show] do
        member do
          post :read
        end
        collection do
          post :read_all
          post :opt_out
          post :opt_in
        end
      end

      resources :tickets, only: %i[index create show] do
        member do
          post :vote
          delete :vote, action: :unvote
        end
      end

      get "roadmap", to: "roadmap#index"
    end
  end

  resource :session
  resources :passwords, param: :token

  resources :contacts, only: %i[index show destroy]
  resources :announcements
  resources :segment_values, only: %i[create destroy]
  resources :segments
  resources :tickets do
    collection { get :timeline }
  end

  get "roadmap", to: "public_roadmap#index"

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", :as => :rails_health_check

  get "script.js", to: "welcome#script"

  # Defines the root path route ("/")
  root "welcome#home"
end
