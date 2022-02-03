class CreateObjectVersion < ActiveRecord::Migration[5.2]
  def change
    create_table :object_versions do |t|
      t.string :druid, null: false
      t.integer :version, null: false      
      t.string :tag
      t.string :description
      t.timestamps
    end

    add_index :object_versions, :druid
    add_index :object_versions, [:druid, :version], unique: true
  end
end
