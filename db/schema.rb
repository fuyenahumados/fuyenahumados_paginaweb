# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_08_19_030425) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "access_tokens", force: :cascade do |t|
    t.boolean "activo", default: true, null: false
    t.datetime "created_at", null: false
    t.string "token", null: false
    t.datetime "updated_at", null: false
    t.index ["token"], name: "index_access_tokens_on_token", unique: true
  end

  create_table "direcciones", force: :cascade do |t|
    t.string "calle", null: false
    t.string "comuna", null: false
    t.datetime "created_at", null: false
    t.string "etiqueta", null: false
    t.string "numero_depto"
    t.boolean "principal", default: false, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_direcciones_on_user_id"
  end

  create_table "order_items", force: :cascade do |t|
    t.integer "cantidad", null: false
    t.datetime "created_at", null: false
    t.bigint "order_id", null: false
    t.decimal "precio_unitario", precision: 10, scale: 2, null: false
    t.bigint "product_id", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_order_items_on_order_id"
    t.index ["product_id"], name: "index_order_items_on_product_id"
  end

  create_table "order_status_changes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "estado", null: false
    t.bigint "order_id", null: false
    t.datetime "updated_at", null: false
    t.index ["order_id"], name: "index_order_status_changes_on_order_id"
  end

  create_table "orders", force: :cascade do |t|
    t.string "apellido_contacto"
    t.string "codigo_pedido", null: false
    t.datetime "created_at", null: false
    t.string "direccion_calle"
    t.string "direccion_comuna"
    t.string "direccion_numero_depto"
    t.string "email_contacto"
    t.decimal "envio", precision: 10, scale: 2, default: "0.0", null: false
    t.integer "estado", default: 0, null: false
    t.date "fecha_entrega", null: false
    t.decimal "lat", precision: 10, scale: 6
    t.decimal "lng", precision: 10, scale: 6
    t.string "nombre_contacto"
    t.text "notas"
    t.string "telefono_contacto"
    t.decimal "total", precision: 10, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["codigo_pedido"], name: "index_orders_on_codigo_pedido", unique: true
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  create_table "products", force: :cascade do |t|
    t.boolean "activo", default: true, null: false
    t.integer "categoria", default: 0, null: false
    t.datetime "created_at", null: false
    t.text "descripcion"
    t.string "foto_filename"
    t.string "nombre", null: false
    t.string "peso_descripcion"
    t.decimal "precio", precision: 10, scale: 2, null: false
    t.integer "stock", default: 0, null: false
    t.datetime "updated_at", null: false
  end

  create_table "resenas", force: :cascade do |t|
    t.integer "calificacion", null: false
    t.text "comentario"
    t.datetime "created_at", null: false
    t.bigint "product_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["product_id"], name: "index_resenas_on_product_id"
    t.index ["user_id", "product_id"], name: "index_resenas_on_user_id_and_product_id", unique: true
    t.index ["user_id"], name: "index_resenas_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "apellido"
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "nombre"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "role", default: 0, null: false
    t.string "telefono"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "direcciones", "users"
  add_foreign_key "order_items", "orders"
  add_foreign_key "order_items", "products"
  add_foreign_key "order_status_changes", "orders"
  add_foreign_key "orders", "users"
  add_foreign_key "resenas", "products"
  add_foreign_key "resenas", "users"
end
