class CreateDro < ActiveRecord::Migration[5.2]
  def change
    create_table :dros do |t|
      t.string :druid, null: false
      # Type is reserved by Rails.
      t.string :content_type, null: false
      t.string :label, null: false
      t.integer :version, null: false
      t.jsonb :access, null: false
      t.jsonb :administrative, null: false
      t.jsonb :description
      t.jsonb :identification
      t.jsonb :structural
      t.jsonb :geographic
      t.timestamps
      t.index :druid, unique: true
    end
  end
end
