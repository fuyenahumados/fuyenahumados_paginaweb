class SwitchProductFotoToStaticAsset < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :foto_filename, :string

    drop_table :active_storage_variant_records do |t|
      t.bigint :blob_id, null: false
      t.string :variation_digest, null: false
    end

    drop_table :active_storage_attachments do |t|
      t.string :name, null: false
      t.bigint :record_id, null: false
      t.string :record_type, null: false
      t.bigint :blob_id, null: false
      t.datetime :created_at, precision: 6, null: false
    end

    drop_table :active_storage_blobs do |t|
      t.string :key, null: false
      t.string :filename, null: false
      t.string :content_type
      t.text :metadata
      t.string :service_name, null: false
      t.bigint :byte_size, null: false
      t.string :checksum
      t.datetime :created_at, precision: 6, null: false
    end
  end
end
