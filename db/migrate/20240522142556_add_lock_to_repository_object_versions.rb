class AddLockToRepositoryObjectVersions < ActiveRecord::Migration[7.1]
  def change
    add_column :repository_object_versions, :lock, :integer
  end
end
