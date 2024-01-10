# frozen_string_literal: true

class WorkflowFields
  def self.for(druid:, version:)
    new(druid:, version:).result
  end

  attr_reader :druid, :version

  def initialize(druid:, version:)
    @druid = druid
    @version = version
  end

  # @return [Hash] the partial solr document for processable concerns
  def result
    Rails.logger.debug { "In #{self.class}" }

    {}.tap do |solr_doc|
      add_sortable_milestones(solr_doc)
      add_status(solr_doc)
    end
  end

  private

  def status_service
    @status_service ||= WorkflowClientFactory.build.status(druid:, version:)
  end

  def add_status(solr_doc)
    # This is the status on the Argo show page (e.g. "v4 In accessioning (described, published, deposited)")
    solr_doc['status_ssi'] = status_service.display
    return unless status_service.info[:status_code]

    # This is used for Argo's "Processing Status" facet
    solr_doc['processing_status_text_ssi'] = status_service.display_simplified
  end

  def sortable_milestones
    status_service.milestones.each_with_object({}) do |milestone, sortable|
      sortable[milestone[:milestone]] ||= []
      sortable[milestone[:milestone]] << milestone[:at].utc.xmlschema
    end
  end

  def add_sortable_milestones(solr_doc)
    sortable_milestones.each do |milestone, unordered_dates|
      dates = unordered_dates.sort
      # create the published_dttsi and published_day fields and the like
      dates.each do |date|
        solr_doc["#{milestone}_dttsim"] ||= []
        solr_doc["#{milestone}_dttsim"] << date unless solr_doc["#{milestone}_dttsim"].include?(date)
      end
      # fields for OAI havester to sort on: _dttsi is trie date +stored +indexed (single valued, i.e. sortable)
      # TODO: we really only need accessioned_earliest and registered_earliest
      solr_doc["#{milestone}_earliest_dttsi"] = dates.first
      solr_doc["#{milestone}_latest_dttsi"] = dates.last
    end
  end
end
