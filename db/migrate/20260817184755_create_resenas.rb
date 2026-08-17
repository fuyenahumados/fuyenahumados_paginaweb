class CreateResenas < ActiveRecord::Migration[8.1]
  def change
    create_table :resenas do |t|
      t.references :user, null: false, foreign_key: true
      t.references :product, null: false, foreign_key: true
      t.integer :calificacion, null: false
      t.text :comentario

      t.timestamps
    end

    # Un cliente reseña un producto una sola vez.
    add_index :resenas, [ :user_id, :product_id ], unique: true
  end
end
