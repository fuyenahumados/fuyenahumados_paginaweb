class AddCategoriaToProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :categoria, :integer, default: 0, null: false
  end
end
