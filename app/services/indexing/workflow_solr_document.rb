# frozen_string_literal: true

module Indexing
  # Represents that part of the solr document that holds workflow data
  class WorkflowSolrDocument
    WORKFLOW_SOLR = 'wf_ssim'
    # field that indexes workflow name, process status then process name
    WORKFLOW_WPS_SOLR = 'wf_wps_ssimdv'
    WORKFLOW_HIERARCHICAL_WPS_SOLR = 'wf_hierarchical_wps_ssimdv'
    WORKFLOW_ERROR_SOLR = 'wf_error_ssim'
    WORKFLOW_STATUS_SOLR = 'workflow_status_ssim'

    # For hierarchical workflow fields
    # They have the format: [LEVEL]|[WORKFLOW DATA]|[LEAF OR BRANCH]
    # For example: "3|accessionWF:start-accession:completed|-"
    DELIMITER = '|'
    BRANCH = '+'
    LEAF = '-'

    KEYS_TO_MERGE = [
      WORKFLOW_SOLR,
      WORKFLOW_WPS_SOLR,
      WORKFLOW_HIERARCHICAL_WPS_SOLR,
      WORKFLOW_STATUS_SOLR,
      WORKFLOW_ERROR_SOLR
    ].freeze

    # These are either deprecated or aren't useful to have indexed in the wps field
    SKIP_WPS_WORKFLOWS = %w[
      accession2WF
      sdrMigrationWF
      dpgImageWF
      sdrAuditWF
      swIndexWF
      googleScannedBookWF
      eemsAccessionWF
      gisDiscoveryWF
      etdSubmitWF
      hydrusAssemblyWF
      disseminationWF
      registrationWF
      versioningWF
    ].freeze

    def initialize
      @data = empty_document
      yield self if block_given?
    end

    def name=(wf_name)
      @wf_name = wf_name
      data[WORKFLOW_SOLR] += [wf_name]
      return if skip_wps_workflow?

      data[WORKFLOW_WPS_SOLR] += [wf_name]
      data[WORKFLOW_HIERARCHICAL_WPS_SOLR] += [to_hierarchical(wf_name)]
    end

    def status=(status)
      data[WORKFLOW_STATUS_SOLR] += [status]
    end

    def error=(message)
      data[WORKFLOW_ERROR_SOLR] += [message]
    end

    # Add to the field that indexes workflow name, process status then process name
    def add_wps(*messages)
      return if skip_wps_workflow?

      data[WORKFLOW_WPS_SOLR] += messages
      data[WORKFLOW_HIERARCHICAL_WPS_SOLR] += messages.map { |m| to_hierarchical(m) }
    end

    # Add the processes data_time attribute to the solr document
    # @param [String] wf_name
    # @param [String] process_name
    # @param [Time] time
    def add_process_time(wf_name, process_name, time)
      data["wf_#{wf_name}_#{process_name}_dttsi"] = time.utc.iso8601
    end

    def to_h
      KEYS_TO_MERGE.each { |k| data[k].uniq! }
      data
    end

    delegate :except, :[], to: :data

    # @param [WorkflowSolrDocument] doc
    def merge!(doc)
      # This is going to get the date fields, e.g. `wf_assemblyWF_jp2-create_dttsi'
      @data.merge!(doc.except(*KEYS_TO_MERGE))

      # Combine the non-unique fields together
      KEYS_TO_MERGE.each do |k|
        data[k] += doc[k]
      end
    end

    private

    attr_reader :data, :wf_name

    def empty_document
      KEYS_TO_MERGE.index_with { |_k| [] }
    end

    def to_hierarchical(message)
      level = message.count(':') + 1
      leaf = (level == 3)
      [level, message, (leaf ? LEAF : BRANCH)].join(DELIMITER)
    end

    def skip_wps_workflow?
      Settings.skip_workflows.include?(wf_name)
    end
  end
end
