class CreateCollection < ActiveRecord::Migration[5.2]
  def change
    create_table :collections do |t|
      t.string :druid, null: false
      # Type is reserved by Rails.
      t.string :content_type, null: false
      t.string :label, null: false
      t.integer :version, null: false
      t.jsonb :access, null: false
      t.jsonb :administrative
      t.jsonb :description
      t.jsonb :identification
      t.timestamps
      t.index :druid, unique: true
    end
  end
end
