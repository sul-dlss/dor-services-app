class CreateRepositoryObjectVersions < ActiveRecord::Migration[7.1]
  def change
    create_table :repository_object_versions do |t|
      t.references :repository_object, null: false, foreign_key: true
      t.integer :version, null: false
      t.string :version_description, null: false
      t.integer :cocina_version
      t.string :content_type
      t.string :label
      t.jsonb :access
      t.jsonb :administrative
      t.jsonb :description
      t.jsonb :identification
      t.jsonb :structural
      t.jsonb :geographic
      t.datetime :closed_at

      t.timestamps
    end

    add_index :repository_object_versions, "(structural#>'{hasMemberOrders,0}'->'members')", using: 'gin'
    add_index :repository_object_versions, "(structural->'isMemberOf')", using: 'gin'
  end
end
