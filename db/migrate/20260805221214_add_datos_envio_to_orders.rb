class AddDatosEnvioToOrders < ActiveRecord::Migration[8.1]
  def change
    add_column :orders, :nombre_contacto, :string
    add_column :orders, :apellido_contacto, :string
    add_column :orders, :telefono_contacto, :string
    add_column :orders, :direccion_calle, :string
    add_column :orders, :direccion_comuna, :string
  end
end
