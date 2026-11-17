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

ActiveRecord::Schema[8.1].define(version: 2026_11_17_003117) do
  create_table "active_storage_attachments", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "articulos", primary_key: "id_articulo", id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.column "almacen", "enum('oficina','uno','dos','tres','dormitorios')"
    t.float "cantidad_en_stock"
    t.boolean "es_cable", default: false
    t.string "nombre", limit: 100, null: false
    t.string "num_catalogo", limit: 100
    t.decimal "precio_unitario", precision: 12, scale: 2
    t.integer "proveedor"
    t.float "stock_minimo"
    t.column "tipo", "enum('material','herramienta')", null: false
    t.column "ubicacion", "enum('nivel_1','nivel_2','planta_baja','estante_compras','nivel_1_AA')"
    t.string "unidad_medida", limit: 50
    t.index ["proveedor"], name: "id_proveedor_idx"
  end

  create_table "detalle_movimientos", primary_key: "id_detalle", id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.float "cantidad", null: false
    t.integer "id_articulo", null: false
    t.integer "id_movimiento", null: false
    t.integer "id_punta"
    t.decimal "precio_unitario", precision: 12, scale: 2
    t.index ["id_articulo"], name: "detalle_movimientos_ibfk_3_idx"
    t.index ["id_movimiento"], name: "index_detalle_movimientos_on_id_movimiento"
    t.index ["id_punta"], name: "index_detalle_movimientos_on_id_punta"
  end

  create_table "documentos", id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "id_trabajador", null: false
    t.index ["id_trabajador"], name: "index_documentos_on_id_trabajador", unique: true
  end

  create_table "epp_movimientos", id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.boolean "barbiquejo", default: false, null: false
    t.boolean "botas", default: false, null: false
    t.boolean "casco", default: false, null: false
    t.boolean "chaleco", default: false, null: false
    t.datetime "fecha_y_hora", null: false
    t.boolean "guantes", default: false, null: false
    t.integer "id_trabajador", null: false
    t.boolean "lentes", default: false, null: false
    t.column "tipo_de_movimiento", "enum('entrega_primera_vez','reemplazo_por_desgaste','reemplazo_por_perdida')", null: false
    t.index ["id_trabajador"], name: "index_epp_movimientos_on_id_trabajador"
  end

  create_table "grupos", id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "nombre", limit: 50, null: false
    t.index ["nombre"], name: "index_grupos_on_nombre", unique: true
  end

  create_table "movimientos", primary_key: "id_movimiento", id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "fecha_hora"
    t.integer "id_proveedor"
    t.integer "id_proyecto"
    t.string "moneda", limit: 3
    t.text "observaciones"
    t.string "responsable", limit: 100
    t.column "tipo", "enum('entrada','salida','compra')", null: false
    t.index ["id_proveedor"], name: "index_movimientos_on_id_proveedor"
    t.index ["id_proyecto"], name: "index_movimientos_on_id_proyecto"
  end

  create_table "proveedores", primary_key: "id_proveedor", id: :integer, default: nil, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "contacto", limit: 45
    t.string "direccion", limit: 45
    t.string "email", limit: 60
    t.string "entrega_estado", default: "desconocida", null: false
    t.string "entrega_moneda", limit: 3
    t.decimal "entrega_monto_minimo", precision: 12, scale: 2
    t.string "nombre", limit: 60
    t.string "notas", limit: 100
    t.string "pagina_web", limit: 45
    t.string "telefono", limit: 45
  end

  create_table "proyectos", primary_key: "id_proyecto", id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "c_c", limit: 50, null: false
    t.string "encargado", limit: 45
    t.string "nombre_obra", limit: 150
    t.index ["c_c"], name: "codigo_obra", unique: true
  end

  create_table "stock_puntas", primary_key: "id_punta", id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "color", limit: 30
    t.integer "id_articulo", null: false
    t.decimal "longitud", precision: 10, scale: 2, null: false
    t.string "nombre_punta", limit: 45
    t.index ["id_articulo"], name: "inventario_stock_ibfk_1"
  end

  create_table "trabajadores_datos", id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.boolean "activo", default: true, null: false
    t.column "antidoping", "enum('apto','no_apto')"
    t.string "cel_emergencia", limit: 45
    t.string "cel_personal", limit: 45
    t.string "credencial_ingreso", limit: 100
    t.string "curp", limit: 18
    t.string "especialidad_obra", limit: 100
    t.integer "grupo_id", null: false
    t.integer "id_usse", null: false
    t.string "nombre", limit: 150, null: false
    t.string "puesto_imss", limit: 100
    t.string "puesto_magnet", limit: 100
    t.string "rfc", limit: 13
    t.column "tipo_sangre", "enum('O+','O-','A+','A-','B+','B-','AB+','AB-')"
    t.index ["grupo_id"], name: "index_trabajadores_datos_on_grupo_id"
    t.index ["id_usse"], name: "index_trabajadores_datos_on_id_usse", unique: true
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "acceso", default: "ambos", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "first_name", limit: 100
    t.string "last_name", limit: 100
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "role", default: "consulta", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "articulos", "proveedores", column: "proveedor", primary_key: "id_proveedor", name: "id_proveedor"
  add_foreign_key "detalle_movimientos", "articulos", column: "id_articulo", primary_key: "id_articulo"
  add_foreign_key "detalle_movimientos", "movimientos", column: "id_movimiento", primary_key: "id_movimiento"
  add_foreign_key "detalle_movimientos", "stock_puntas", column: "id_punta", primary_key: "id_punta"
  add_foreign_key "documentos", "trabajadores_datos", column: "id_trabajador"
  add_foreign_key "epp_movimientos", "trabajadores_datos", column: "id_trabajador"
  add_foreign_key "movimientos", "proveedores", column: "id_proveedor", primary_key: "id_proveedor"
  add_foreign_key "movimientos", "proyectos", column: "id_proyecto", primary_key: "id_proyecto"
  add_foreign_key "stock_puntas", "articulos", column: "id_articulo", primary_key: "id_articulo"
  add_foreign_key "trabajadores_datos", "grupos"
end
