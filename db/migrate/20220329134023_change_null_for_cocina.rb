class ChangeNullForCocina < ActiveRecord::Migration[5.2]
  def change
    change_column_null(:collections, :description, false)
    change_column_null(:collections, :administrative, false)
    change_column_null(:collections, :identification, false)
    change_column_null(:dros, :description, false)
    change_column_null(:dros, :structural, false)
    change_column_null(:dros, :identification, false)
  end
end
