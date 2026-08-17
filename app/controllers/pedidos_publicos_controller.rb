class PedidosPublicosController < ApplicationController
  def nuevo
  end

  def buscar
    codigo = params[:codigo_pedido].to_s.strip.upcase

    if Order.exists?(codigo_pedido: codigo)
      redirect_to pedido_publico_path(codigo)
    else
      redirect_to nuevo_pedido_publico_path, alert: "No encontramos ningún pedido con ese código."
    end
  end

  def show
    @pedido = Order.includes(order_items: :product).find_by!(codigo_pedido: params[:codigo])
  rescue ActiveRecord::RecordNotFound
    redirect_to nuevo_pedido_publico_path, alert: "No encontramos ningún pedido con ese código."
  end
end
