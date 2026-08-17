class AddNombreToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :nombre, :string
  end
end
