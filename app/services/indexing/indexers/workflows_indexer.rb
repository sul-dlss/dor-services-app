# frozen_string_literal: true

module Indexing
  module Indexers
    # Indexes the object's state in the most recent execution of every one of its workflows
    class WorkflowsIndexer
      attr_reader :id

      def initialize(id:, **)
        @id = id
      end

      # @return [Hash] the partial solr document for workflows concerns
      def to_solr
        WorkflowSolrDocument.new do |combined_doc|
          workflows.each do |wf|
            doc = WorkflowIndexer.new(workflow: wf).to_solr
            combined_doc.merge!(doc)
          end
        end.to_h
      end

      private

      # @return [Array<Workflow::Response::Workflows>]
      def workflows
        WorkflowService.workflows(druid: id)
      end
    end
  end
end
