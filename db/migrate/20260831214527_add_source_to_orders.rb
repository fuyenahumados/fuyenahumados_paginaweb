class AddSourceToOrders < ActiveRecord::Migration[8.1]
  def change
    add_column :orders, :source, :string, null: false, default: "web"
  end
end
