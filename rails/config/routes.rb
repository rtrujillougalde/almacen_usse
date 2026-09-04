Rails.application.routes.draw do
  devise_for :users, skip: [:registrations]

  get "up" => "rails/health#show", as: :rails_health_check

  get "inventario", to: "inventario#index", as: :inventario
  get "entradas", to: "entradas#index", as: :entradas
  get "salidas", to: "salidas#index", as: :salidas
  get "proyectos", to: "proyectos#index", as: :proyectos
  get "reportes", to: "reportes#index", as: :reportes
  get "proveedores", to: "proveedores#index", as: :proveedores

  root "inventario#index"
end
