Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html
  post "flixsearch/create"

  # Defines the root path route ("/")
  root "flixsearch#index"
end
