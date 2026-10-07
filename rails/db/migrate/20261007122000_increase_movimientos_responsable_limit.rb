# frozen_string_literal: true

class IncreaseMovimientosResponsableLimit < ActiveRecord::Migration[8.1]
  def change
    change_column :movimientos, :responsable, :string, limit: 100
  end
end
