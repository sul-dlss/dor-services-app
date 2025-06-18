# frozen_string_literal: true

class RemoveDefault < ActiveRecord::Migration[5.2]
  def change
    change_column_default(:workflow_steps, :version, nil) # rubocop:disable Rails/ReversibleMigration
  end
end
