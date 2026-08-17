require "test_helper"

class ProductTest < ActiveSupport::TestCase
  test "requiere nombre" do
    producto = Product.new(nombre: nil, precio: 1000, stock: 1)
    assert_not producto.valid?
    assert_includes producto.errors[:nombre], "no puede estar en blanco"
  end

  test "el precio debe ser mayor a cero" do
    producto = crear_producto
    producto.precio = 0
    assert_not producto.valid?

    producto.precio = -100
    assert_not producto.valid?
  end

  test "el stock no puede ser negativo pero sí cero" do
    producto = crear_producto
    producto.stock = -1
    assert_not producto.valid?

    producto.stock = 0
    assert producto.valid?
  end

  test "acepta extensiones de foto válidas y rechaza otras" do
    producto = crear_producto(foto_filename: "salmon.jpg")
    assert producto.valid?

    producto.foto_filename = "salmon.exe"
    assert_not producto.valid?
    assert_includes producto.errors[:foto_filename], "debe ser un archivo .jpg, .jpeg, .png o .webp"
  end

  test "foto_filename en blanco es válido (no hay foto todavía)" do
    producto = crear_producto(foto_filename: nil)
    assert producto.valid?
  end

  test "foto_url arma la ruta estática solo si hay foto_filename" do
    con_foto = crear_producto(foto_filename: "salmon.jpg")
    assert_equal "/docs/productos/salmon.jpg", con_foto.foto_url

    sin_foto = crear_producto(foto_filename: nil)
    assert_nil sin_foto.foto_url
  end

  test "scope activos solo trae productos activos" do
    activo = crear_producto(activo: true)
    inactivo = crear_producto(activo: false)

    assert_includes Product.activos, activo
    assert_not_includes Product.activos, inactivo
  end

  test "scope con_stock solo trae productos con stock mayor a cero" do
    con_stock = crear_producto(stock: 5)
    sin_stock = crear_producto(stock: 0)

    assert_includes Product.con_stock, con_stock
    assert_not_includes Product.con_stock, sin_stock
  end

  test "calificacion_promedio es nil sin reseñas y promedia las que hay" do
    producto = crear_producto
    assert_nil producto.calificacion_promedio

    cliente_a = crear_cliente
    cliente_b = crear_cliente
    crear_pedido(usuario: cliente_a, productos: producto)
    crear_pedido(usuario: cliente_b, productos: producto)
    Resena.create!(user: cliente_a, product: producto, calificacion: 4)
    Resena.create!(user: cliente_b, product: producto, calificacion: 5)

    assert_equal 4.5, producto.calificacion_promedio
  end

  test "scope disponibles combina activos y con stock" do
    disponible = crear_producto(activo: true, stock: 5)
    inactivo = crear_producto(activo: false, stock: 5)
    sin_stock = crear_producto(activo: true, stock: 0)

    assert_includes Product.disponibles, disponible
    assert_not_includes Product.disponibles, inactivo
    assert_not_includes Product.disponibles, sin_stock
  end
end
