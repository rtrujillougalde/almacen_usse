class ChangeProyectosCcToString < ActiveRecord::Migration[8.1]
  def change
    change_column :proyectos, :c_c, :string, limit: 50, null: false
  end
end
