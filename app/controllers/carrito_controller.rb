class CarritoController < ApplicationController
  before_action :solo_clientes

  def show
  end

  def agregar
    product = Product.disponibles.find_by(id: params[:product_id])

    unless product
      redirect_to root_path, alert: "Producto no disponible." and return
    end

    cantidad = params[:cantidad].presence&.to_i || 1
    session[:carrito] ||= {}
    nueva_cantidad = session[:carrito][product.id.to_s].to_i + cantidad
    session[:carrito][product.id.to_s] = [ nueva_cantidad, product.stock ].min

    respond_to do |format|
      format.turbo_stream do
        streams = [ turbo_stream.replace("nav-carrito", partial: "shared/nav_carrito") ]
        # El id "producto-accion-#{id}" solo existe en la grilla/ficha con stepper (no en la
        # página de detalle, que tiene su propio form) — Turbo Stream ignora en silencio un
        # replace cuyo target no está en la página, así que es seguro incluirlo siempre.
        streams << turbo_stream.replace("producto-accion-#{product.id}", partial: "productos/accion_carrito", locals: { product: product })
        if params[:mostrar_modal] == "true"
          streams << turbo_stream.update("modal-carrito", partial: "carrito/modal", locals: { product: product, cantidad_agregada: cantidad })
        end
        render turbo_stream: streams
      end
      format.html { redirect_to carrito_path, notice: "#{product.nombre} agregado al carrito." }
    end
  end

  def actualizar
    product = Product.disponibles.find_by(id: params[:product_id])

    unless product
      redirect_to root_path, alert: "Producto no disponible." and return
    end

    cantidad = params[:cantidad].to_i.clamp(0, product.stock)
    session[:carrito] ||= {}

    if cantidad.zero?
      session[:carrito].delete(product.id.to_s)
    else
      session[:carrito][product.id.to_s] = cantidad
    end

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: streams_actualizar(product)
      end
      format.html { redirect_to carrito_path }
    end
  end

  def quitar
    product_id = params[:product_id].to_s
    session[:carrito]&.delete(product_id)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.update("carrito-content", partial: "carrito/contenido"),
          turbo_stream.replace("nav-carrito", partial: "shared/nav_carrito")
        ]
      end
      format.html { redirect_to carrito_path, notice: "Producto eliminado del carrito." }
    end
  end

  private

  def streams_actualizar(product)
    if params[:origen] == "carrito"
      [
        turbo_stream.update("carrito-content", partial: "carrito/contenido"),
        turbo_stream.replace("nav-carrito", partial: "shared/nav_carrito")
      ]
    else
      [
        turbo_stream.replace("producto-accion-#{product.id}", partial: "productos/accion_carrito", locals: { product: product }),
        turbo_stream.replace("nav-carrito", partial: "shared/nav_carrito")
      ]
    end
  end
end
