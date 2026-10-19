# frozen_string_literal: true

class RemoveCategoriaFromArticulos < ActiveRecord::Migration[8.1]
  def up
    remove_column :articulos, :categoria
  end
end
