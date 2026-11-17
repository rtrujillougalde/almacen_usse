# frozen_string_literal: true

class AddAccesoToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :acceso, :string, null: false, default: "ambos"
  end
end
