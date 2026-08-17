class ResenasController < ApplicationController
  before_action :authenticate_user!
  before_action :solo_clientes
  before_action :set_product

  def create
    @resena = @product.resenas.new(resena_params.merge(user: current_user))

    if @resena.save
      redirect_to producto_path(@product), notice: "Gracias por tu reseña."
    else
      redirect_to producto_path(@product), alert: @resena.errors.full_messages.to_sentence
    end
  end

  private

  def set_product
    @product = Product.disponibles.find(params[:producto_id])
  end

  def resena_params
    params.require(:resena).permit(:calificacion, :comentario)
  end
end
