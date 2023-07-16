class CreateOrcidWorks < ActiveRecord::Migration[7.0]
  def change
    create_table :orcid_works do |t|
      t.string :orcidid, null: false
      t.string :put_code, null: false
      t.string :druid, null: false
      t.string :md5, null: false
      t.timestamps
      t.index [:orcidid, :druid], unique: true
    end
  end
end
