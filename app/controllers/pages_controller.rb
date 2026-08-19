class PagesController < ApplicationController
  def inicio
    @productos = Product.disponibles.order(:nombre)
  end

  def nosotros
  end

  def preguntas_frecuentes
  end
end
