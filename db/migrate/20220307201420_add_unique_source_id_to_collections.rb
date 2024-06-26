class AddUniqueSourceIdToCollections < ActiveRecord::Migration[5.2]
  def change
    ActiveRecord::Base.connection.execute("CREATE UNIQUE INDEX collection_source_id_idx ON collections( (identification ->> 'sourceId') );")
  end
end
