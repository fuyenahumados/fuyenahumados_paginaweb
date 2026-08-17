class CreateOrderStatusChanges < ActiveRecord::Migration[8.1]
  def change
    create_table :order_status_changes do |t|
      t.references :order, null: false, foreign_key: true
      t.string :estado, null: false

      t.timestamps
    end
  end
end
