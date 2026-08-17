class CreateAccessTokens < ActiveRecord::Migration[8.1]
  def change
    create_table :access_tokens do |t|
      t.string :token, null: false
      t.boolean :activo, null: false, default: true

      t.timestamps
    end

    add_index :access_tokens, :token, unique: true
  end
end
