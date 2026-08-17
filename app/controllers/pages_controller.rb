class PagesController < ApplicationController
  def inicio
    @productos = Product.disponibles.order(:nombre)
  end

  def nosotros
  end
end
