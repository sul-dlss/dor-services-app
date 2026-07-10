class DropMarcCacheEntry < ActiveRecord::Migration[8.0]
  def change
    drop_table :marc_cache_entries
  end
end
