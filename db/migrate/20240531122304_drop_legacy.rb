class DropLegacy < ActiveRecord::Migration[7.1]
  def change
    drop_table :object_versions
    drop_table :dros
    drop_table :collections
    drop_table :admin_policies
  end
end
