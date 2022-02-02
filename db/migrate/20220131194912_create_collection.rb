class CreateCollection < ActiveRecord::Migration[5.2]
  def change
    create_table :collections do |t|
      t.string :external_identifier, null: false
      t.string :cocina_version, null: false
      # Type is reserved by Rails.
      t.string :collection_type, null: false
      t.string :label, null: false
      t.integer :version, null: false
      t.jsonb :access, null: false
      t.jsonb :administrative
      t.jsonb :description
      t.jsonb :identification
      t.timestamps
      t.index :external_identifier, unique: true      
    end
  end
end
