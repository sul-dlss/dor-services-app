class CreateCollectionVersions < ActiveRecord::Migration[5.2]
  def change
    create_table :collection_versions do |t|
      t.string :druid, null: false
      # Type is reserved by Rails.
      t.string :content_type
      t.string :label
      t.integer :version
      t.jsonb :access
      t.jsonb :administrative
      t.jsonb :description
      t.jsonb :identification
      t.timestamps
      t.references :collection, null: false
      t.index :druid
    end
    add_foreign_key :collection_versions, :collections, on_delete: :cascade
  end
end
