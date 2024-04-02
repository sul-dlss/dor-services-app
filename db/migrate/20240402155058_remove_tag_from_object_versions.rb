class RemoveTagFromObjectVersions < ActiveRecord::Migration[7.1]
  def change
    remove_column :object_versions, :tag, :string
  end
end
