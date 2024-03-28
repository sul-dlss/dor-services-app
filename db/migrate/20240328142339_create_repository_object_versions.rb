class CreateRepositoryObjectVersions < ActiveRecord::Migration[7.1]
  def change
    create_table :repository_object_versions do |t|
      t.references :repository_object, null: false, foreign_key: true
      t.integer :version, null: false
      t.string :version_description
      t.integer :cocina_version, null: false
      t.string :content_type, null: false
      t.string :label, null: false
      t.jsonb :access
      t.jsonb :administrative, null: false
      t.jsonb :description
      t.jsonb :identification
      t.jsonb :structural
      t.jsonb :geographic
      t.datetime :closed_at

      t.timestamps
    end
  end
end
