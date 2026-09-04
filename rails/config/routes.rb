Rails.application.routes.draw do
  devise_for :users, skip: [:registrations]

  get "up" => "rails/health#show", as: :rails_health_check

  resources :proveedores, only: %i[index new create edit update]
  resources :proyectos, only: %i[index create]
  resources :articulos, only: %i[edit update]
  resources :entradas, only: %i[index create]
  resources :salidas, only: %i[index create]

  get "inventario", to: "inventario#index", as: :inventario
  get "reportes", to: "reportes#index", as: :reportes

  root "inventario#index"
end
