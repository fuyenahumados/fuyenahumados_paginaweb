require "test_helper"

class DireccionTest < ActiveSupport::TestCase
  test "requiere etiqueta, comuna y calle" do
    usuario = crear_cliente
    direccion = usuario.direcciones.new(etiqueta: nil, comuna: nil, calle: nil, numero_depto: nil)
    assert_not direccion.valid?
    assert_includes direccion.errors[:etiqueta], "no puede estar en blanco"
    assert_includes direccion.errors[:comuna], "no puede estar en blanco"
    assert_includes direccion.errors[:calle], "no puede estar en blanco"
  end

  test "numero_depto es opcional" do
    usuario = crear_cliente
    direccion = usuario.direcciones.new(etiqueta: "Casa", comuna: "Providencia", calle: "Cerro de Ramón 12334", numero_depto: nil)
    assert direccion.valid?
  end

  test "direccion_completa arma la dirección saltándose el numero_depto si está vacío" do
    direccion = Direccion.new(calle: "Cerro de Ramón 12334", numero_depto: nil, comuna: "La Reina")
    assert_equal "Cerro de Ramón 12334, La Reina", direccion.direccion_completa

    direccion.numero_depto = "Casa 8"
    assert_equal "Cerro de Ramón 12334, Casa 8, La Reina", direccion.direccion_completa
  end

  test "la comuna debe estar en la lista fija" do
    usuario = crear_cliente
    direccion = usuario.direcciones.new(etiqueta: "Casa", comuna: "Santiago Centro", calle: "Calle 123")
    assert_not direccion.valid?
    assert_includes direccion.errors[:comuna], "no está incluido en la lista"
  end

  test "la primera dirección de un usuario siempre queda como principal" do
    usuario = crear_cliente
    direccion = crear_direccion(usuario, etiqueta: "Casa")
    assert direccion.principal?
  end

  test "marcar una nueva dirección como principal desmarca las demás" do
    usuario = crear_cliente
    casa = crear_direccion(usuario, etiqueta: "Casa")
    oficina = crear_direccion(usuario, etiqueta: "Oficina")

    oficina.update!(principal: true)

    assert oficina.reload.principal?
    assert_not casa.reload.principal?
  end

  test "al borrar la dirección principal se promueve otra automáticamente" do
    usuario = crear_cliente
    casa = crear_direccion(usuario, etiqueta: "Casa")
    oficina = crear_direccion(usuario, etiqueta: "Oficina")
    assert casa.principal?

    casa.destroy

    assert oficina.reload.principal?
  end

  test "borrar una dirección no principal no cambia la principal" do
    usuario = crear_cliente
    casa = crear_direccion(usuario, etiqueta: "Casa")
    oficina = crear_direccion(usuario, etiqueta: "Oficina")

    oficina.destroy

    assert casa.reload.principal?
  end
end
