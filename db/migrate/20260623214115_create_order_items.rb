class CreateOrderItems < ActiveRecord::Migration[8.1]
  def change
    create_table :order_items do |t|
      t.references :order,           null: false, foreign_key: true
      t.references :product,         null: false, foreign_key: true
      t.integer    :cantidad,        null: false
      t.decimal    :precio_unitario, null: false, precision: 10, scale: 2

      t.timestamps
    end
  end
end
