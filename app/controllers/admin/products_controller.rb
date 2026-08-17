class Admin::ProductsController < Admin::BaseController
  before_action :set_product, only: [ :edit, :update, :destroy ]

  def index
    @products = Product.order(:nombre)
  end

  def new
    @product = Product.new
  end

  def create
    @product = Product.new(product_params)
    if @product.save
      redirect_to admin_products_path, notice: "#{@product.nombre} creado."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @product.update(product_params)
      redirect_to admin_products_path, notice: "#{@product.nombre} actualizado."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @product.order_items.exists?
      redirect_to admin_products_path, alert: "#{@product.nombre} tiene pedidos asociados y no se puede eliminar. Desactívalo en su lugar."
    else
      @product.destroy
      redirect_to admin_products_path, notice: "#{@product.nombre} eliminado."
    end
  end

  private

  def set_product
    @product = Product.find(params[:id])
  end

  def product_params
    params.require(:product).permit(:nombre, :descripcion, :peso_descripcion, :precio, :stock, :activo, :foto_filename, :categoria)
  end
end
