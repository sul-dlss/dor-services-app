class RequireObjectVersions < ActiveRecord::Migration[5.2]
  def change
    ActiveRecord::Base.connection.execute("update object_versions set tag = concat(version::varchar, '.0.0') where tag is null;")
    ActiveRecord::Base.connection.execute("update object_versions set description = concat('Version ', tag) where description is null;")
    change_column_null :object_versions, :tag, false
    change_column_null :object_versions, :description, false
  end
end
