class CreateDirecciones < ActiveRecord::Migration[8.1]
  def change
    create_table :direcciones do |t|
      t.references :user, null: false, foreign_key: true
      t.string :etiqueta, null: false
      t.string :comuna, null: false
      t.string :calle, null: false
      t.decimal :lat, precision: 10, scale: 6
      t.decimal :lng, precision: 10, scale: 6
      t.boolean :principal, null: false, default: false

      t.timestamps
    end
  end
end
