class ProductosController < ApplicationController
  ORDENES = {
    "precio_asc"  => { precio: :asc },
    "precio_desc" => { precio: :desc },
    "nombre_asc"  => { nombre: :asc },
    "nombre_desc" => { nombre: :desc },
    "recientes"   => { created_at: :desc }
  }.freeze

  RANGOS_PRECIO = [
    [ "0-4990",     "Hasta $4.990" ],
    [ "4990-9990",  "$4.990 - $9.990" ],
    [ "9990-14990", "$9.990 - $14.990" ],
    [ "14990-19990", "$14.990 - $19.990" ],
    [ "19990-",     "Más de $19.990" ]
  ].freeze

  def index
    @products = Product.disponibles

    if params[:buscar].present?
      termino = "%#{params[:buscar].strip}%"
      @products = @products.where("nombre ILIKE :t OR descripcion ILIKE :t", t: termino)
    end

    if params[:categoria].present? && Product.categorias.key?(params[:categoria])
      @products = @products.where(categoria: params[:categoria])
    end

    if (rango = RANGOS_PRECIO.assoc(params[:precio_rango]))
      desde, hasta = rango.first.split("-")
      @products = @products.where("precio >= ?", desde) if desde.present?
      @products = @products.where("precio <= ?", hasta) if hasta.present?
    end

    @products = @products.order(ORDENES.fetch(params[:orden], nombre: :asc))
  end

  def show
    @product = Product.disponibles.find(params[:id])
    @resenas = @product.resenas.includes(:user).order(created_at: :desc)
    @puede_resenar = user_signed_in? && current_user.cliente? &&
                      current_user.compro?(@product) &&
                      @resenas.none? { |r| r.user_id == current_user.id }
  end
end
