# frozen_string_literal: true

class WorkflowStepCompletedAt < ActiveRecord::Migration[6.0]
  def change
    add_column :workflow_steps, :completed_at, :datetime, null: true

    # This is too slow. We will do it manually, not at deploy time.
    # defaults all completed current rows to set the completed_at to the last time they were updated,
    # new rows will be set accordingly
    # reversible do |dir|
    #   dir.up { WorkflowStep.complete.update_all('completed_at = updated_at') }
    # end
  end
end
