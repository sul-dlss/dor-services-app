# frozen_string_literal: true

# Models optional context that is associated with a druid/version pair for any workflow
class VersionContext < WorkflowApplicationRecord
  has_many :workflow_steps, foreign_key: %i[druid version], primary_key: %i[druid version], dependent: :destroy,
                            inverse_of: :version_context

  validates :druid, uniqueness: { scope: :version }
  validates_with DruidValidator
end
