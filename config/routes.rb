Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # Defines the root path route ("/")
  # root "posts#index"

  root "home#index"
  get "map", to: "map#show", as: :map
  get "weather", to: "weather#show", as: :weather

  get "location/search", to: "location#search", as: :location_search

  post "clicks/increment", to: "clicks#increment"

  get "game/home", to: "game#home", as: :game_home
  get "game/play", to: "game#play", as: :game_play
  get "game/result", to: "game#result", as: :game_result
end
