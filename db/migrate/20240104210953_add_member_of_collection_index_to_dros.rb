class AddMemberOfCollectionIndexToDros < ActiveRecord::Migration[7.1]
  def change
    add_index :dros, "(structural->'isMemberOf')", using: 'gin'
  end
end
