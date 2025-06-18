# frozen_string_literal: true

class CreateWfsRailsWorkflows < ActiveRecord::Migration[5.0]
  def change
    create_table :wfs_rails_workflows do |t|
      t.string      :druid, null: false
      t.string      :datastream, null: false
      t.string      :process, null: false
      t.string      :status
      t.text        :error_msg
      t.binary      :error_txt
      t.integer     :attempts, default: 0, null: false
      t.string      :lifecycle
      t.decimal     :elapsed, precision: 9, scale: 3
      t.string      :repository
      t.integer     :version, default: 1
      t.text        :note
      t.integer     :priority, default: 0
      t.string      :lane_id, default: 'default', null: false
      t.timestamps null: false
    end
  end
end
