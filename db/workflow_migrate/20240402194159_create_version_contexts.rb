# frozen_string_literal: true

class CreateVersionContexts < ActiveRecord::Migration[7.0]
  def change
    create_table :version_contexts do |t|
      t.string      :druid, null: false
      t.integer     :version, null: false, default: 1
      t.jsonb       :values, default: {}
      t.timestamps
    end

    add_index :version_contexts, %i[druid version], unique: true
  end
end
