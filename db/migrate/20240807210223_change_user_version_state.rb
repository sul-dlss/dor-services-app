class ChangeUserVersionState < ActiveRecord::Migration[7.1]
  def change
    add_column :user_versions, :state, :string, default: 'available', null: false

    execute <<~SQL
      UPDATE user_versions SET state = 'withdrawn' WHERE withdrawn = true;
    SQL

    remove_column :user_versions, :withdrawn
  end
end
