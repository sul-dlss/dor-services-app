class CreateDroVersions < ActiveRecord::Migration[5.2]
  def change
    create_table :dro_versions do |t|
      t.string :druid, null: false
      # Type is reserved by Rails.
      t.string :content_type
      t.string :label
      t.integer :version
      t.jsonb :access
      t.jsonb :administrative
      t.jsonb :description
      t.jsonb :identification
      t.jsonb :structural
      t.jsonb :geographic
      t.timestamps
      t.references :dro, null: false
      t.index :druid
    end
    add_foreign_key :dro_versions, :dros, on_delete: :cascade
  end
end
