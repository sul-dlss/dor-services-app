class AddUniqueSourceIdToDros < ActiveRecord::Migration[5.2]
  def change
    Dro.connection.execute("CREATE UNIQUE INDEX dro_source_id_idx ON dros( (identification ->> 'sourceId') );")
  end
end
