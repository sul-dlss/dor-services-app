class CreateRepositoryObjects < ActiveRecord::Migration[7.1]
  def change
    create_table :repository_objects do |t|
      t.string :type, null: false
      t.string :external_identifier, null: false
      t.integer :lock

      t.timestamps
    end
  end
end
