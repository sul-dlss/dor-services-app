class DropLabelFromRepositoryObjectVersions < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!
  
  def change
    remove_column :repository_object_versions, :label, :string
  end
end
