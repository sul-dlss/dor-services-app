# frozen_string_literal: true

class RenameDatastreamToWorkflow < ActiveRecord::Migration[5.2]
  def change
    rename_column :workflow_steps, :datastream, :workflow
  end
end
