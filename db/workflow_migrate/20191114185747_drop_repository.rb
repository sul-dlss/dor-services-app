# frozen_string_literal: true

class DropRepository < ActiveRecord::Migration[5.2]
  def change
    remove_column :workflow_steps, :repository, :string
  end
end
