class CreateTagLabels < ActiveRecord::Migration[5.2]
  def change
    create_table :tag_labels do |t|
      t.string :tag, null: false

      t.timestamps
    end
    add_index :tag_labels, [:tag], unique: true
  end
end
