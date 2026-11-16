# frozen_string_literal: true

class ReplaceUsernameWithNameOnUsers < ActiveRecord::Migration[8.1]
  def up
    add_column :users, :first_name, :string, limit: 100
    add_column :users, :last_name, :string, limit: 100
    add_column :users, :active, :boolean, null: false, default: true

    # Existing accounts only have a username, so it becomes the first name.
    execute "UPDATE users SET first_name = username"

    remove_index :users, :username
    remove_column :users, :username
  end

  def down
    add_column :users, :username, :string
    execute "UPDATE users SET username = COALESCE(NULLIF(first_name, ''), email)"
    change_column_null :users, :username, false
    add_index :users, :username, unique: true

    remove_column :users, :active
    remove_column :users, :last_name
    remove_column :users, :first_name
  end
end
