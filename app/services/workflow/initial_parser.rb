# frozen_string_literal: true

module Workflow
  # Parsing initial Workflow
  # That is, as created by Workflow::Transformer.initial_workflow, not workflow template)
  class InitialParser
    attr_reader :workflow_doc

    # @param [Nokogiri::XML::Document] Initial workflow as XML
    def initialize(workflow_doc)
      @workflow_doc = workflow_doc
    end

    # @return [Array<ProcessParser>] a parser for each process element
    def processes
      workflow.xpath('//process').map do |process|
        ProcessParser.new(
          process: process.attr('name'),
          status: process.attr('status'),
          lane_id: process.attr('laneId'),
          elapsed: process.attr('elapsed'),
          lifecycle: process.attr('lifecycle'),
          note: process.attr('note'),
          error_msg: process.attr('errorMsg'),
          error_txt: process.attr('errorTxt')
        )
      end
    end

    # @return [String] the workflow identifier
    def workflow_id
      @workflow_id ||= begin
        node = workflow.attr('id')
        raise 'Workflow did not provide a required @id attribute' unless node

        node.value
      end
    end

    private

    def workflow
      workflow_doc.xpath('//workflow')
    end
  end
end
