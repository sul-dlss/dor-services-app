# frozen_string_literal: true

class AddIndexes < ActiveRecord::Migration[5.2]
  def change
    add_index :wfs_rails_workflows, [:druid]
    add_index :wfs_rails_workflows, %i[druid version]
  end
end
