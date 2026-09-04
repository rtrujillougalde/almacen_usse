# frozen_string_literal: true

class CreateAlmacenDomainTables < ActiveRecord::Migration[8.1]
  def change
    create_table :proveedores, id: false, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci" do |t|
      t.integer :id_proveedor, null: false, primary_key: true, auto_increment: false
      t.string :nombre, limit: 60
      t.string :telefono, limit: 45
      t.string :direccion, limit: 45
      t.string :pagina_web, limit: 45
      t.string :contacto, limit: 45
      t.string :notas, limit: 100
      t.string :email, limit: 60
    end

    create_table :proyectos, primary_key: :id_proyecto, id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci" do |t|
      t.integer :c_c, null: false
      t.string :nombre_obra, limit: 150
      t.string :encargado, limit: 45

      t.index :c_c, unique: true, name: "codigo_obra"
    end

    create_table :articulos, primary_key: :id_articulo, id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci" do |t|
      t.string :nombre, limit: 100, null: false
      t.string :num_catalogo, limit: 100
      t.column :tipo, "enum('material','herramienta')", null: false
      t.float :cantidad_en_stock
      t.string :unidad_medida, limit: 50
      t.boolean :es_cable, default: false
      t.column :categoria, "enum('albañileria','aire_acondicionado','aislantes','almacen_dormitorios','alumbrado','baterias','c_d','cables','calentadores','canalizaciones','charolas','cinchos','conductor','contactos','contactos_regulados','control_almacen','control_acceso','datos','eléctrico','equipo_medición','equipo_protección','fibra_óptica','fuse_panel','fusibles','gasolina','general','herramienta','herrería','interruptores','kit_cursos','limpieza','miscelaneos','motores','papelería','pintura','planta_emergencia','plomeria','racks','referencia','registros','regletas','seguridad','soportes','tablaroca','tableros','tierras','tornilleria','zapatas')"
      t.float :stock_minimo
      t.float :precio_unitario
      t.integer :proveedor
      t.column :almacen, "enum('oficina','uno','dos','tres','dormitorios')"
      t.column :ubicacion, "enum('nivel_1','nivel_2','planta_baja','estante_compras')"

      t.index :proveedor, name: "id_proveedor_idx"
    end
    add_foreign_key :articulos, :proveedores, column: :proveedor, primary_key: :id_proveedor, name: "id_proveedor"

    create_table :movimientos, primary_key: :id_movimiento, id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci" do |t|
      t.integer :id_proyecto
      t.column :tipo, "enum('entrada','salida')", null: false
      t.datetime :fecha_hora
      t.text :observaciones
      t.string :responsable, limit: 45

      t.index :id_proyecto
    end
    add_foreign_key :movimientos, :proyectos, column: :id_proyecto, primary_key: :id_proyecto

    create_table :stock_puntas, primary_key: :id_punta, id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci" do |t|
      t.integer :id_articulo, null: false
      t.string :nombre_punta, limit: 45
      t.decimal :longitud, precision: 10, scale: 2, null: false
      t.string :color, limit: 30

      t.index :id_articulo, name: "inventario_stock_ibfk_1"
    end
    add_foreign_key :stock_puntas, :articulos, column: :id_articulo, primary_key: :id_articulo

    create_table :detalle_movimientos, primary_key: :id_detalle, id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci" do |t|
      t.integer :id_movimiento, null: false
      t.integer :id_articulo, null: false
      t.integer :id_punta
      t.float :cantidad, null: false

      t.index :id_movimiento
      t.index :id_articulo, name: "detalle_movimientos_ibfk_3_idx"
      t.index :id_punta
    end
    add_foreign_key :detalle_movimientos, :movimientos, column: :id_movimiento, primary_key: :id_movimiento
    add_foreign_key :detalle_movimientos, :stock_puntas, column: :id_punta, primary_key: :id_punta
    add_foreign_key :detalle_movimientos, :articulos, column: :id_articulo, primary_key: :id_articulo
  end
end
