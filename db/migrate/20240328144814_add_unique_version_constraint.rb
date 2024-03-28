class AddUniqueVersionConstraint < ActiveRecord::Migration[7.1]
  def change
    add_index :repository_object_versions, [:repository_object_id, :version], unique: true
  end
end
