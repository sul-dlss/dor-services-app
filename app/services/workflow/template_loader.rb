# frozen_string_literal: true

module Workflow
  # Loading workflow templates
  class TemplateLoader
    WORKFLOWS_DIR = Rails.root.join('config/workflows').freeze

    # Loads a workflow template from file as XML
    # @param [String] workflow_name name/id of workflow, e.g., accessionWF
    # @return [Nokogiri::XML::Document or nil] the workflow as XML or nil if not found
    def self.load_as_xml(workflow_name)
      new(workflow_name).load_as_xml
    end

    @cache = {}
    class << self
      attr_reader :cache
    end

    # @param [String] workflow_name name/id of workflow, e.g., accessionWF
    def initialize(workflow_name)
      @workflow_name = workflow_name
      self.class.cache[workflow_name] ||= load
    end

    # @return [String or nil] the filepath of the workflow file or nil if not found
    def workflow_filepath
      @workflow_filepath ||= "#{WORKFLOWS_DIR}/#{workflow_name}.xml"
    end

    # @return [boolean] true if the workflow file is found
    def exists?
      self.class.cache[workflow_name].present?
    end

    # @return [Nokogiri::XML::Document or nil] contents of the workflow file as XML or nil if not found
    def load_as_xml
      self.class.cache[workflow_name]
    end

    attr_reader :workflow_name

    private

    def load
      File.exist?(workflow_filepath) ? Nokogiri::XML(File.read(workflow_filepath)) : nil
    end
  end
end
