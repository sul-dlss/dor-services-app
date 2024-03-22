class ChangeObjectVersionTagNull < ActiveRecord::Migration[7.1]
  def change
    change_column_null :object_versions, :tag, true
  end
end
