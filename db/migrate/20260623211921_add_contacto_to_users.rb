class AddContactoToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :telefono, :string
    add_column :users, :comuna, :string
    add_column :users, :direccion, :string
  end
end
