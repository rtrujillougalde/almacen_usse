# frozen_string_literal: true

class CreatePersonalTables < ActiveRecord::Migration[8.1]
  def change
    create_table :grupos, id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci" do |t|
      t.string :nombre, limit: 50, null: false

      t.index :nombre, unique: true
    end

    create_table :trabajadores_datos, id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci" do |t|
      t.boolean :activo, null: false, default: true
      t.string :nombre, limit: 150, null: false
      t.string :cel_personal, limit: 45
      t.string :cel_emergencia, limit: 45
      t.integer :id_usse, null: false
      t.string :curp, limit: 18
      t.string :puesto_magnet, limit: 100
      t.string :especialidad_obra, limit: 100
      t.string :puesto_imss, limit: 100
      t.string :credencial_ingreso, limit: 100
      t.string :rfc, limit: 13
      t.column :antidoping, "enum('apto','no_apto')"
      t.column :tipo_sangre, "enum('O+','O-','A+','A-','B+','B-','AB+','AB-')"
      t.integer :grupo_id, null: false

      t.index :id_usse, unique: true
      t.index :grupo_id
    end
    add_foreign_key :trabajadores_datos, :grupos, column: :grupo_id

    create_table :documentos, id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci" do |t|
      t.integer :id_trabajador, null: false

      t.index :id_trabajador, unique: true
    end
    add_foreign_key :documentos, :trabajadores_datos, column: :id_trabajador

    create_table :epp_movimientos, id: :integer, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci" do |t|
      t.integer :id_trabajador, null: false
      t.column :tipo_de_movimiento, "enum('entrega_primera_vez','reemplazo_por_desgaste','reemplazo_por_perdida')", null: false
      t.boolean :casco, null: false, default: false
      t.boolean :guantes, null: false, default: false
      t.boolean :barbiquejo, null: false, default: false
      t.boolean :lentes, null: false, default: false
      t.boolean :botas, null: false, default: false
      t.boolean :chaleco, null: false, default: false
      t.datetime :fecha_y_hora, null: false

      t.index :id_trabajador
    end
    add_foreign_key :epp_movimientos, :trabajadores_datos, column: :id_trabajador
  end
end
