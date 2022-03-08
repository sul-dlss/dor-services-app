# frozen_string_literal: true

require 'fedora_cache'
require 'active_fedora/solr_service'

# Monkeypatch to retrieve tags using dor-services-client so that does not need to be run on dor-services-app server.
class AdministrativeTags
  @@tag_cache = {} # rubocop:disable Style/ClassVars

  def self.project(identifier:)
    tag = self.for(identifier: identifier).find { |check_tag| check_tag.start_with?('Project :') }

    return [] unless tag

    [tag.split(' : ', 2).last]
  end

  def self.content_type(identifier:)
    tag = self.for(identifier: identifier).find { |check_tag| check_tag.start_with?('Process : Content Type :') }

    return [] unless tag

    [tag.split(' : ').last]
  end

  def self.for(identifier:)
    cached_tags = @@tag_cache[identifier]
    return cached_tags if cached_tags

    tags = Dor::Services::Client.object(identifier).administrative_tags.list
    @@tag_cache[identifier] = tags
    tags
  end

  def self.cache(identifier:, tags:)
    @@tag_cache[identifier] = tags
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

    AdministrativeTags.cache(identifier: druid, tags: tags) if tags

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
  def fedora_class(rels_ext)
    rels_ext_ng_xml = Nokogiri::XML(rels_ext)

    raise ExpectedUnmapped unless MigrationFilter.migrate?(rels_ext_ng_xml)

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
    return Dor::Agreement if models.include?('info:fedora/afmodel:Dor_Agreement')

    # Otherwise unexpected unmapped
    raise Unmapped
  end

  # rubocop:enable Metrics/CyclomaticComplexity
  def models_for(rels_ext_ng_xml)
    # Some items have incorrect RELS-EXT, no also checking info:fedora/fedora-system:def/relations-external#
    has_model_nodes = rels_ext_ng_xml.root.xpath('//fedora-model:hasModel',
                                                 'fedora-model' => 'info:fedora/fedora-system:def/model#') + \
                      rels_ext_ng_xml.root.xpath('//fedora-model:hasModel',
                                                 'fedora-model' => 'info:fedora/fedora-system:def/relations-external#')

    has_model_nodes.map do |has_model_node|
      has_model_node['rdf:resource']
    end
  end
end
