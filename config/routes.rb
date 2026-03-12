Rails.application.routes.draw do
  mount Rswag::Ui::Engine => "/api-docs"
  mount Rswag::Api::Engine => "/api-docs"
  mount Motor::Admin => "/motor_admin"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      post "auth/register", to: "auth#register"
      post "auth/login",    to: "auth#login"

      resource :organization, only: [] do
        put    :update_logo,  on: :member
        delete :destroy_logo, on: :member
      end

      resources :raffles, only: [ :index, :show, :create, :update, :destroy ] do
        member do
          post :open
          post :close
        end
      end

      namespace :super_admin do
        resources :organizations
      end
    end
  end

  # Defines the root path route ("/")
  # root "posts#index"
end
