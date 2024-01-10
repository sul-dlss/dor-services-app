class AddVirtualObjectIndexToDros < ActiveRecord::Migration[7.1]
  def change
    add_index :dros, "(structural#>'{hasMemberOrders,0}'->'members')", using: 'gin'
  end
end
