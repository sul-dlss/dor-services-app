class CreateEvents < ActiveRecord::Migration[5.2]
  def change
    create_table :events do |t|
      t.string :event_type, null: false
      t.string :druid, null: false
      t.jsonb :data
      t.datetime :created_at
    end
    add_index :events, :event_type
    add_index :events, :druid
    add_index :events, :created_at
  end
end
