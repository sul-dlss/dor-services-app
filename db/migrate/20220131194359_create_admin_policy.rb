class CreateAdminPolicy < ActiveRecord::Migration[5.2]
  def change
    create_table :admin_policies do |t|
      t.string :external_identifier, null: false
      t.string :cocina_version, null: false
      t.string :label, null: false
      t.integer :version, null: false
      t.jsonb :administrative, null: false
      t.jsonb :description
      t.timestamps
      t.index :external_identifier, unique: true      
    end
  end
end
