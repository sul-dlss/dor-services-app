# frozen_string_literal: true

class RemovePriorityFromWorkflowSteps < ActiveRecord::Migration[5.2]
  def change
    remove_column :workflow_steps, :priority # rubocop:disable Rails/ReversibleMigration
  end
end
