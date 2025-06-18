# frozen_string_literal: true

class AddIndexesWithoutRepository < ActiveRecord::Migration[5.2]
  def change
    add_index :workflow_steps, %i[active_version status workflow process],
              name: 'active_version_step_name_workflow2_idx'
    add_index :workflow_steps, %i[status workflow process druid], name: 'step_name_with_druid_workflow2_idx'
    add_index :workflow_steps, %i[status workflow process], name: 'step_name_workflow2_idx'
  end
end
