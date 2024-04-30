class AddForeignKeyToUserVersion < ActiveRecord::Migration[7.1]
  def change
    remove_reference :user_versions, :repository_object_version, index: true
    add_reference :user_versions, :repository_object_version, null: false, foreign_key: true
  end
end
