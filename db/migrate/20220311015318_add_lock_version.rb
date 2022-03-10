class AddLockVersion < ActiveRecord::Migration[5.2]
  def change
    add_column :dros, :lock, :integer
    add_column :collections, :lock, :integer
    add_column :admin_policies, :lock, :integer
  end
end
