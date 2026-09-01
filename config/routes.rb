Rails.application.routes.draw do
  devise_for :users, controllers: {
    registrations: "users/registrations",
    omniauth_callbacks: "users/omniauth_callbacks"
  }

  get "acceso/:token", to: "acceso#entrar",   as: :acceso
  get "acceso",        to: "acceso#invalido",  as: :acceso_invalido

  resource :carrito,  only: [ :show ], controller: :carrito do
    post   :agregar
    patch  :actualizar
    delete :quitar
  end

  resource :checkout, only: [ :show, :create ], controller: :checkout

  get  "mi-pedido",                   to: "pedidos_publicos#nuevo",     as: :nuevo_pedido_publico
  post "mi-pedido",                   to: "pedidos_publicos#buscar",    as: :buscar_pedido_publico
  get  "mi-pedido/:codigo",           to: "pedidos_publicos#show",      as: :pedido_publico
  get  "mi-pedido/:codigo/descargar", to: "pedidos_publicos#descargar", as: :descargar_pedido_publico

  get "perfil", to: "perfil#show", as: :perfil

  resources :direcciones, only: [ :new, :create, :edit, :update, :destroy ]

  namespace :admin do
    root to: "pedidos#index"
    resources :pedidos, only: [ :index, :show, :new, :create ] do
      member do
        patch :avanzar_estado
        patch :cancelar
      end
      collection do
        get :exportar
      end
    end
    resources :products, only: [ :index, :new, :create, :edit, :update, :destroy ]
    resources :users,    only: [ :index, :show, :destroy ] do
      member do
        patch :resetear_password
      end
    end
  end

  resources :productos, only: [ :index, :show ] do
    resources :resenas, only: [ :create ]
  end
  get "nosotros",  to: "pages#nosotros",  as: :nosotros
  get "preguntas-frecuentes", to: "pages#preguntas_frecuentes", as: :preguntas_frecuentes

  get "up" => "rails/health#show", as: :rails_health_check

  root to: "pages#inicio"
end
