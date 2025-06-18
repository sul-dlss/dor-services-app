# frozen_string_literal: true

# Common superclass for Workflow ActiveRecord-based models
class WorkflowApplicationRecord < ApplicationRecord
  self.abstract_class = true

  connects_to database: { writing: :workflow, reading: :workflow }
end
