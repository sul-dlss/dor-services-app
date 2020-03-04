class CreateAdministrativeTags < ActiveRecord::Migration[5.2]
  def change
    create_table :administrative_tags do |t|
      t.string :druid, null: false
      t.string :tag, null: false

      t.timestamps
    end

    add_index :administrative_tags, :druid
    add_index :administrative_tags, :tag
    add_index :administrative_tags, [:druid, :tag], unique: true
  end
end
