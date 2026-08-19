class AddLatLngToOrders < ActiveRecord::Migration[8.1]
  def change
    add_column :orders, :lat, :decimal, precision: 10, scale: 6
    add_column :orders, :lng, :decimal, precision: 10, scale: 6
  end
end
