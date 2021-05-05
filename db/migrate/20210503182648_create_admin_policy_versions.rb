class CreateAdminPolicyVersions < ActiveRecord::Migration[5.2]
  def change
    create_table :admin_policy_versions do |t|
      t.string :druid, null: false
      t.string :label
      t.integer :version
      t.jsonb :administrative
      t.jsonb :description
      t.timestamps
      t.references :admin_policy, null: false
      t.index :druid
    end
    add_foreign_key :admin_policy_versions, :admin_policies, on_delete: :cascade
  end
end
