# frozen_string_literal: true

# Give these columns more descriptive names
class RenameVersionColumns < ActiveRecord::Migration[7.1]
  def change
    rename_column :repository_objects, :head_id, :last_closed_version_id
    rename_column :repository_objects, :current_id, :head_version_id
    rename_column :repository_objects, :open_id, :opened_version_id
  end
end
