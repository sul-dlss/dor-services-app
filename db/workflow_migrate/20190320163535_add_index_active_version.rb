# frozen_string_literal: true

class AddIndexActiveVersion < ActiveRecord::Migration[5.2]
  def change
    add_index :workflow_steps, %i[active_version status workflow process repository],
              name: 'active_version_step_name_workflow_idx'
  end
end
