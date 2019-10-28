class AddModelTypeToOrmResources < ActiveRecord::Migration[5.2]
  def change
    add_column :orm_resources, :resource_type, :string
  end
end
