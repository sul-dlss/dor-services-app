class IndexAdministrativeTagsLabels < ActiveRecord::Migration[5.2]
  def change
    add_index :administrative_tags, [:druid, :tag_label_id], unique: true
  end
end
