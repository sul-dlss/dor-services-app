class RemoveAdministrativeTagStringField < ActiveRecord::Migration[5.2]
  def change
    add_foreign_key :administrative_tags, :tag_labels
    change_column_null :administrative_tags, :tag_label_id, false
    remove_column :administrative_tags, :tag, :string
  end
end
