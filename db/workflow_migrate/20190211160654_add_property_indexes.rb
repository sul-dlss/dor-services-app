# frozen_string_literal: true

class AddPropertyIndexes < ActiveRecord::Migration[5.2]
  def change
    add_index :workflow_steps, %i[status workflow process repository], name: 'step_name_workflow_idx'
  end
end
