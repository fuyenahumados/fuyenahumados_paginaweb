class AddNumeroDeptoToDirecciones < ActiveRecord::Migration[8.1]
  def change
    add_column :direcciones, :numero_depto, :string
  end
end
