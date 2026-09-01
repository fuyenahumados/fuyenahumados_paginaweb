class DropAccessTokens < ActiveRecord::Migration[8.1]
  def up
    drop_table :access_tokens
  end

  def down
    create_table :access_tokens do |t|
      t.string :token, null: false
      t.boolean :activo, default: true, null: false
      t.timestamps
    end
    add_index :access_tokens, :token, unique: true
  end
end
