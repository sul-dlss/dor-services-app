# frozen_string_literal: true

require 'fedora_cache'
require 'active_fedora/solr_service'

# Monkeypatch to retrieve tags using dor-services-client so that does not need to be run on dor-services-app server.
class AdministrativeTags
  @@tag_cache = {} # rubocop:disable Style/ClassVars

  def self.project(pid:)
    tag = self.for(pid: pid).find { |check_tag| check_tag.start_with?('Project :') }

    return [] unless tag

    [tag.split(' : ', 2).last]
  end

  def self.content_type(pid:)
    tag = self.for(pid: pid).find { |check_tag| check_tag.start_with?('Process : Content Type :') }

    return [] unless tag

    [tag.split(' : ').last]
  end

  def self.for(pid:)
    cached_tags = @@tag_cache[pid]
    return cached_tags if cached_tags

    tags = Dor::Services::Client.object(pid).administrative_tags.list
    @@tag_cache[pid] = tags
    tags
  end

  def self.cache(pid:, tags:)
    @@tag_cache[pid] = tags
  end
end

module ActiveFedora
  # Monkeypatch to avoid hitting Solr.
  class SolrService
    def self.query(query)
      return unless (match = query.match(/druid:.{11}/))

      [{ 'id' => match[0] }]
    end

    def self.reify_solr_results(_result)
      []
    end
  end
end

# Supports loading from cache to a Fedora object with a little bit of monkeypatching.
class FedoraLoader
  class BadCache < StandardError; end

  class ExpectedUnmapped < StandardError; end
  class Unmapped < StandardError; end

  delegate :cached?, to: :@cache

  def initialize(cache:)
    @cache = cache
  end

  def load(druid)
    result = cache.label_and_datastreams_and_tags(druid)
    raise BadCache if result.failure?

    label, datastreams, tags = result.value!

    raise BadCache unless datastreams.key?('RELS-EXT')

    AdministrativeTags.cache(pid: druid, tags: tags) if tags

    obj = fedora_class(datastreams['RELS-EXT']).new(pid: druid, label: label)
    FedoraCache::DATASTREAMS.each do |dsid|
      datastream = datastreams[dsid]
      obj.datastreams[dsid].content = datastream if datastream && obj.datastreams[dsid]
    end
    obj.relationships = obj.rels_ext.content
    obj
  end

  private

  attr_reader :cache

  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  def fedora_class(rels_ext)
    rels_ext_ng_xml = Nokogiri::XML(rels_ext)

    raise ExpectedUnmapped if rels_ext_ng_xml.root.xpath('//fedora:conformsTo[@rdf:resource="info:fedora/afmodel:Part"]',
                                                         'fedora' => 'info:fedora/fedora-system:def/relations-external#',
                                                         'rdf' => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#').present?

    models = models_for(rels_ext_ng_xml)

    # Mappings
    return Dor::Collection if models.include?('info:fedora/afmodel:Dor_Collection')
    return Dor::Collection if models.include?('info:fedora/afmodel:Hydrus_Collection')
    return Dor::AdminPolicyObject if models.include?('info:fedora/afmodel:Dor_AdminPolicyObject')
    return Dor::AdminPolicyObject if models.include?('info:fedora/afmodel:Hydrus_AdminPolicyObject')
    return Dor::Item if models.include?('info:fedora/afmodel:Dor_Item')
    return Dor::Item if models.include?('info:fedora/dor:googleScannedBook')
    return Dor::Item if models.include?('info:fedora/afmodel:Hydrus_Item')
    return Dor::Item if models.include?('info:fedora/afmodel:Etd')
    return Dor::Item if models.include?('info:fedora/afmodel:Eems')
    return Dor::Item if models.include?('info:fedora/afmodel:Eem')

    # Expected unmapped
    raise ExpectedUnmapped if models.include?('info:fedora/afmodel:Part')
    raise ExpectedUnmapped if models.include?('info:fedora/afmodel:PermissionFile')

    # Otherwise unexpected unmapped
    raise Unmapped
  end
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/PerceivedComplexity

  def models_for(rels_ext_ng_xml)
    has_model_nodes = rels_ext_ng_xml.root.xpath('//fedora-model:hasModel', 'fedora-model' => 'info:fedora/fedora-system:def/model#')

    has_model_nodes.map do |has_model_node|
      has_model_node['rdf:resource']
    end
  end
end
