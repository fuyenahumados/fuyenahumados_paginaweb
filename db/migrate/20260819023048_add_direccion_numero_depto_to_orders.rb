class AddDireccionNumeroDeptoToOrders < ActiveRecord::Migration[8.1]
  def change
    add_column :orders, :direccion_numero_depto, :string
  end
end
