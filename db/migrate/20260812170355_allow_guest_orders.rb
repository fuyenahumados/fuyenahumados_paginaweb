class AllowGuestOrders < ActiveRecord::Migration[8.1]
  def change
    change_column_null :orders, :user_id, true
    add_column :orders, :email_contacto, :string
  end
end
