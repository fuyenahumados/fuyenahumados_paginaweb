module CarritoConcern
  extend ActiveSupport::Concern

  included do
    helper_method :carrito_items, :carrito_total, :carrito_envio, :carrito_gran_total, :carrito_count, :carrito_cantidad
  end

  def carrito_items
    return [] if session[:carrito].blank?

    products = Product.where(id: session[:carrito].keys).index_by { |p| p.id.to_s }
    session[:carrito].filter_map do |product_id, cantidad|
      product = products[product_id]
      next unless product

      { product: product, cantidad: cantidad.to_i, subtotal: product.precio * cantidad.to_i }
    end
  end

  def carrito_total
    carrito_items.sum { |item| item[:subtotal] }
  end

  def carrito_envio
    CostoEnvio.calcular(carrito_total)
  end

  def carrito_gran_total
    carrito_total + carrito_envio
  end

  def carrito_count
    return 0 if session[:carrito].blank?
    session[:carrito].values.sum(&:to_i)
  end

  def carrito_cantidad(product)
    return 0 if session[:carrito].blank?
    session[:carrito][product.id.to_s].to_i
  end
end
