class AddTagLabelIdToAdministrativeTags < ActiveRecord::Migration[5.2]
  def change
    add_reference :administrative_tags, :tag_label, index: true
  end
end
