# frozen_string_literal: true

module Migrators
  # Demonstrates passing workflow context when a versioned migration is closed.
  class ExemplarWithContext < ExemplarWithCommitWithVersion
    def self.workflow_context
      { 'skipReleaseWF' => true }
    end
  end
end
