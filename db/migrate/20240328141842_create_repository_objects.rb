class CreateRepositoryObjects < ActiveRecord::Migration[7.1]
  def change
    create_enum :repository_object_type, %w[dro admin_policy collection]

    create_table :repository_objects do |t|
      t.enum :object_type, enum_type: :repository_object_type, null: false
      t.string :external_identifier, null: false
      t.string :source_id, null: true
      t.integer :lock

      t.timestamps
    end

    add_index :repository_objects, :object_type
    add_index :repository_objects, :external_identifier, unique: true
    add_index :repository_objects, :source_id, unique: true
  end
end
