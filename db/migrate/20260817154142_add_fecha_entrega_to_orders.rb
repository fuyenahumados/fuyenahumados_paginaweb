class AddFechaEntregaToOrders < ActiveRecord::Migration[8.1]
  class OrderBackfill < ActiveRecord::Base
    self.table_name = "orders"
  end

  def up
    add_column :orders, :fecha_entrega, :date

    # Pedidos existentes no tenían una fecha de entrega elegida por el cliente
    # (se calculaba al vuelo como "el próximo viernes desde que se creó el pedido").
    # Se backfillea con ese mismo criterio para no dejar pedidos sin fecha.
    say_with_time "Backfilling orders.fecha_entrega" do
      OrderBackfill.reset_column_information
      OrderBackfill.find_each do |order|
        order.update_column(:fecha_entrega, order.created_at.to_date.next_occurring(:friday))
      end
    end

    change_column_null :orders, :fecha_entrega, false
  end

  def down
    remove_column :orders, :fecha_entrega
  end
end
