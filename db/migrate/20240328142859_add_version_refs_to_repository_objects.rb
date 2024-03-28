class AddVersionRefsToRepositoryObjects < ActiveRecord::Migration[7.1]
  def change
    add_reference :repository_objects, :current, null: true, foreign_key: { to_table: :repository_object_versions }
    add_reference :repository_objects, :head, null: true, foreign_key: { to_table: :repository_object_versions }
    add_reference :repository_objects, :open, null: true, foreign_key: { to_table: :repository_object_versions }
  end
end
