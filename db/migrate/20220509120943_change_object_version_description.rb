class ChangeObjectVersionDescription < ActiveRecord::Migration[5.2]
  def change
    ActiveRecord::Base.connection.execute("update object_versions set description = concat('Version ', version) where description = concat('Version ', tag);")
  end
end
