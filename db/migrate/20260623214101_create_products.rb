class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products do |t|
      t.string  :nombre,           null: false
      t.text    :descripcion
      t.string  :peso_descripcion
      t.decimal :precio,           null: false, precision: 10, scale: 2
      t.integer :stock,            null: false, default: 0
      t.boolean :activo,           null: false, default: true

      t.timestamps
    end
  end
end
