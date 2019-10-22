class AddDroTable < ActiveRecord::Migration[5.2]
  def change
    create_table :orm_resources, id: :uuid do |t|
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end
    add_index :orm_resources, :metadata, using: :gin
  end
end
