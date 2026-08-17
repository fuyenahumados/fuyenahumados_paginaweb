Rails.application.routes.draw do
  devise_for :users

  get "acceso/:token", to: "acceso#entrar",   as: :acceso
  get "acceso",        to: "acceso#invalido",  as: :acceso_invalido

  resource :carrito,  only: [ :show ], controller: :carrito do
    post   :agregar
    patch  :actualizar
    delete :quitar
  end

  resource :checkout, only: [ :show, :create ], controller: :checkout

  get  "mi-pedido",         to: "pedidos_publicos#nuevo",  as: :nuevo_pedido_publico
  post "mi-pedido",         to: "pedidos_publicos#buscar", as: :buscar_pedido_publico
  get  "mi-pedido/:codigo", to: "pedidos_publicos#show",   as: :pedido_publico

  get   "perfil",         to: "perfil#show",   as: :perfil
  get   "perfil/editar",  to: "perfil#edit",   as: :editar_perfil
  patch "perfil",         to: "perfil#update"

  resources :direcciones, only: [ :new, :create, :edit, :update, :destroy ]

  namespace :admin do
    root to: "pedidos#index"
    resources :pedidos, only: [ :index, :show ] do
      member do
        patch :avanzar_estado
        patch :cancelar
      end
      collection do
        get :exportar
      end
    end
    resources :products, only: [ :index, :new, :create, :edit, :update, :destroy ]
    resources :users,    only: [ :index, :show, :destroy ]
  end

  resources :productos, only: [ :index, :show ] do
    resources :resenas, only: [ :create ]
  end
  get "nosotros",  to: "pages#nosotros",  as: :nosotros

  get "up" => "rails/health#show", as: :rails_health_check

  root to: "pages#inicio"
end
