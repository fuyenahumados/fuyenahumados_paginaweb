class MigrateUserAddressesToDirecciones < ActiveRecord::Migration[8.1]
  class MigrationUser < ApplicationRecord
    self.table_name = "users"
  end

  class MigrationDireccion < ApplicationRecord
    self.table_name = "direcciones"
  end

  def up
    MigrationUser.reset_column_information
    MigrationUser.where.not(direccion: [nil, ""]).find_each do |user|
      MigrationDireccion.create!(
        user_id:   user.id,
        etiqueta:  "Principal",
        comuna:    user.comuna,
        calle:     user.direccion,
        principal: true
      )
    end

    remove_column :users, :comuna, :string
    remove_column :users, :direccion, :string
  end

  def down
    add_column :users, :comuna, :string
    add_column :users, :direccion, :string
  end
end
