class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      t.references :user,          null: false, foreign_key: true
      t.integer    :estado,        null: false, default: 0
      t.string     :codigo_pedido, null: false
      t.decimal    :total,         null: false, precision: 10, scale: 2
      t.text       :notas

      t.timestamps
    end

    add_index :orders, :codigo_pedido, unique: true
  end
end
