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

ActiveRecord::Schema[8.1].define(version: 2026_09_04_191937) do
  create_table "articulos", primary_key: "id_articulo", id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.column "almacen", "enum('oficina','uno','dos','tres','dormitorios')"
    t.float "cantidad_en_stock"
    t.column "categoria", "enum('albañileria','aire_acondicionado','aislantes','almacen_dormitorios','alumbrado','baterias','c_d','cables','calentadores','canalizaciones','charolas','cinchos','conductor','contactos','contactos_regulados','control_almacen','control_acceso','datos','eléctrico','equipo_medición','equipo_protección','fibra_óptica','fuse_panel','fusibles','gasolina','general','herramienta','herrería','interruptores','kit_cursos','limpieza','miscelaneos','motores','papelería','pintura','planta_emergencia','plomeria','racks','referencia','registros','regletas','seguridad','soportes','tablaroca','tableros','tierras','tornilleria','zapatas')"
    t.boolean "es_cable", default: false
    t.string "nombre", limit: 100, null: false
    t.string "num_catalogo", limit: 100
    t.float "precio_unitario"
    t.integer "proveedor"
    t.float "stock_minimo"
    t.column "tipo", "enum('material','herramienta')", null: false
    t.column "ubicacion", "enum('nivel_1','nivel_2','planta_baja','estante_compras')"
    t.string "unidad_medida", limit: 50
    t.index ["proveedor"], name: "id_proveedor_idx"
  end

  create_table "detalle_movimientos", primary_key: "id_detalle", id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.float "cantidad", null: false
    t.integer "id_articulo", null: false
    t.integer "id_movimiento", null: false
    t.integer "id_punta"
    t.index ["id_articulo"], name: "detalle_movimientos_ibfk_3_idx"
    t.index ["id_movimiento"], name: "index_detalle_movimientos_on_id_movimiento"
    t.index ["id_punta"], name: "index_detalle_movimientos_on_id_punta"
  end

  create_table "movimientos", primary_key: "id_movimiento", id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "fecha_hora"
    t.integer "id_proyecto"
    t.text "observaciones"
    t.string "responsable", limit: 45
    t.column "tipo", "enum('entrada','salida')", null: false
    t.index ["id_proyecto"], name: "index_movimientos_on_id_proyecto"
  end

  create_table "proveedores", primary_key: "id_proveedor", id: :integer, default: nil, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "contacto", limit: 45
    t.string "direccion", limit: 45
    t.string "email", limit: 60
    t.string "nombre", limit: 60
    t.string "notas", limit: 100
    t.string "pagina_web", limit: 45
    t.string "telefono", limit: 45
  end

  create_table "proyectos", primary_key: "id_proyecto", id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.integer "c_c", null: false
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

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "role", default: "consulta", null: false
    t.datetime "updated_at", null: false
    t.string "username", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["username"], name: "index_users_on_username", unique: true
  end

  add_foreign_key "articulos", "proveedores", column: "proveedor", primary_key: "id_proveedor", name: "id_proveedor"
  add_foreign_key "detalle_movimientos", "articulos", column: "id_articulo", primary_key: "id_articulo"
  add_foreign_key "detalle_movimientos", "movimientos", column: "id_movimiento", primary_key: "id_movimiento"
  add_foreign_key "detalle_movimientos", "stock_puntas", column: "id_punta", primary_key: "id_punta"
  add_foreign_key "movimientos", "proyectos", column: "id_proyecto", primary_key: "id_proyecto"
  add_foreign_key "stock_puntas", "articulos", column: "id_articulo", primary_key: "id_articulo"
end
