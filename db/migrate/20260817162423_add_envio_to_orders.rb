class AddEnvioToOrders < ActiveRecord::Migration[8.1]
  def change
    # Pedidos existentes no cobraron envío (la funcionalidad no existía) — 0 por defecto
    # es exactamente correcto para ellos, no hace falta backfill.
    add_column :orders, :envio, :decimal, precision: 10, scale: 2, default: 0, null: false
  end
end
