# Track release of data to Searchworks/Earthworks/etc.
class CreateReleaseTags < ActiveRecord::Migration[7.1]
  def change
    create_table :release_tags do |t|
      t.string :druid, null: false
      t.string :who, null: false
      t.string :what, null: false
      t.string :released_to, null: false
      t.boolean :release, default: false, null: false

      t.timestamps
    end
    add_index :release_tags, :druid
  end
end
