class CreateMarcCacheEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :marc_cache_entries, id: false do |t|
      t.string :folio_hrid, null: false, primary_key: true
      t.jsonb :marc_data, null: false

      t.timestamps
    end
    add_index :marc_cache_entries, :folio_hrid, unique: true
  end
end
