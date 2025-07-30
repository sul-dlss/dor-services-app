# frozen_string_literal: true

# Service for retrieving the workflow state of a batch of objects.
class WorkflowStateBatchService
  def self.accessioning_druids(...)
    new(...).accessioning_druids
  end

  def self.accessioned_druids(...)
    new(...).accessioned_druids
  end

  def self.assembling_druids(...)
    new(...).assembling_druids
  end

  def initialize(druids:)
    @druids = druids
  end

  # @return [Array<String>] list of druids that are currently accessioning
  def accessioning_druids
    WorkflowStep.where(druid: druids, active_version: true, workflow: 'accessionWF')
                .incomplete
                .where.not(process: 'end-accession')
                .select(:druid).distinct.pluck(:druid)
  end

  # @return [Array<String>] list of druids that have been accessioned
  def accessioned_druids
    WorkflowStep.where(druid: druids, lifecycle: 'accessioned')
                .complete
                .select(:druid).distinct.pluck(:druid)
  end

  # rubocop:disable Rails/WhereNotWithMultipleConditions, Metrics/AbcSize
  # @return [Array<String>] list of druids that are currently assembling
  def assembling_druids
    # For any of the assembly workflows, are they are incomplete workflow steps for the active version,
    # ignoring certain final steps that might not be complete yet.
    WorkflowStep
      .where(druid: druids, active_version: true,
             workflow: %w[assemblyWF wasCrawlPreassemblyWF wasSeedPreassemblyWF
                          gisDeliveryWF ocrWF speechToTextWF gisAssemblyWF])
      .incomplete
      .where.not(workflow: 'assemblyWF', process: 'accessioning-initiate')
      .where.not(workflow: 'wasCrawlPreassemblyWF', process: 'end-was-crawl-preassembly')
      .where.not(workflow: 'wasSeedPreassemblyWF', process: 'end-was-seed-preassembly')
      .where.not(workflow: 'gisDeliveryWF', process: 'start-accession-workflow')
      .where.not(workflow: 'ocrWF', process: 'end-ocr')
      .where.not(workflow: 'speechToTextWF', process: 'end-stt')
      .select(:druid).distinct.pluck(:druid)
  end
  # rubocop:enable Rails/WhereNotWithMultipleConditions, Metrics/AbcSize

  private

  attr_reader :druids
end
