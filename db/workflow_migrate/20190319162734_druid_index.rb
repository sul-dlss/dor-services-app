# frozen_string_literal: true

class DruidIndex < ActiveRecord::Migration[5.2]
  def change
    add_index :workflow_steps, %i[status workflow process repository druid], name: 'step_name_with_druid_workflow_idx'
  end
end
