class CreateUserVersions < ActiveRecord::Migration[7.1]
  def change
    create_table :user_versions do |t|
      t.belongs_to :repository_object_version, index: true
      t.integer :version, null: false
      t.boolean :withdrawn, default: false, null: false

      t.timestamps
    end

    add_index :user_versions, :version
  end
end
