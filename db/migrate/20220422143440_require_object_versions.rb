class RequireObjectVersions < ActiveRecord::Migration[5.2]
  def change
    change_column_null :object_versions, :tag, false
    change_column_null :object_versions, :description, false
  end
end
