# frozen_string_literal: true

module Indexing
  module Indexers
    # Indexes the object's state for each process in a single workflow
    class WorkflowIndexer
      # @param [Workflow::Response::Workflow] workflow the workflow document to index
      def initialize(workflow:)
        @workflow = workflow
      end

      # @return [Hash] the partial solr document for all the workflow processes
      def to_solr
        WorkflowSolrDocument.new do |solr_doc|
          solr_doc.name = workflow_name

          errors = 0 # The error count is used by the Report class in Argo
          processes.each do |process|
            WorkflowProcessIndexer.new(solr_doc:, workflow_name:, process:).to_solr
            errors += 1 if process.status == 'error'
          end
          solr_doc.status = [workflow_name, workflow_status, errors].join('|')
        end
      end

      private

      attr_reader :workflow

      delegate :workflow_name, to: :workflow

      def definition_process_names
        @definition_process_names ||= begin
          definition = WorkflowTemplateService.template(workflow_name: workflow_name)
          definition['processes'].pluck('name')
        end
      end

      def processes
        @processes ||= definition_process_names.map do |process_name|
          workflow.process_for_recent_version(name: process_name)
        end
      end

      def workflow_status
        workflow.complete? ? 'completed' : 'active'
      end
    end
  end
end
