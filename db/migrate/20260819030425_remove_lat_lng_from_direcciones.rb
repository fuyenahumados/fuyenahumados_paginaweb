class RemoveLatLngFromDirecciones < ActiveRecord::Migration[8.1]
  def change
    remove_column :direcciones, :lat, :float
    remove_column :direcciones, :lng, :float
  end
end
