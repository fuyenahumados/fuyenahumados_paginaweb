class PerfilController < ApplicationController
  before_action :authenticate_user!
  before_action :solo_clientes

  def show
    @pedidos = current_user.orders.order(created_at: :desc)
    @resenas = current_user.resenas.includes(:product).order(created_at: :desc)
  end
end
