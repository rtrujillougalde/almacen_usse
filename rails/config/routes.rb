Rails.application.routes.draw do
  devise_for :users, skip: [:registrations]

  get "up" => "rails/health#show", as: :rails_health_check

  # Explicit singular helper names so Spanish pluralization cannot break path helpers.
  resources :proveedores, only: %i[index create]
  get "proveedores/new", to: "proveedores#new", as: :new_proveedor
  get "proveedores/:id/edit", to: "proveedores#edit", as: :edit_proveedor
  patch "proveedores/:id", to: "proveedores#update", as: :proveedor
  put "proveedores/:id", to: "proveedores#update"

  resources :proyectos, only: %i[index create]
  resources :articulos, only: %i[edit update]

  resources :entradas, only: %i[index create] do
    collection do
      post :start
      post :add_item
      delete :remove_item
      delete :cancel
      post :finalize
      delete :dismiss_confirmation
    end
  end

  resources :compras, only: %i[index create] do
    collection do
      post :start
      post :add_item
      delete :remove_item
      delete :cancel
      post :finalize
      delete :dismiss_confirmation
    end
  end

  resources :salidas, only: %i[index create] do
    collection do
      post :start
      post :add_item
      delete :remove_item
      delete :cancel
      post :finalize
      delete :dismiss_confirmation
    end
  end

  resources :reportes, only: %i[index create] do
    collection do
      get :download
    end
  end

  get "inventario", to: "inventario#index", as: :inventario

  root "inventario#index"
end
