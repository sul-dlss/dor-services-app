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

  class Unmapped < StandardError; end

  delegate :cached?, to: :@cache

  def initialize(cache:)
    @cache = cache
  end

  def load(druid)
    result = cache.label_and_datastreams(druid)
    raise BadCache if result.failure?

    label, datastreams = result.value!

    raise BadCache unless datastreams.key?('RELS-EXT')

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

  def fedora_class(rels_ext)
    rels_ext_ng_xml = Nokogiri::XML(rels_ext)

    raise Unmapped if rels_ext_ng_xml.root.xpath('//fedora:conformsTo[@rdf:resource="info:fedora/afmodel:Part"]',
                                                 'fedora' => 'info:fedora/fedora-system:def/relations-external#',
                                                 'rdf' => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#').present?

    has_model_nodes = rels_ext_ng_xml.root.xpath('//fedora-model:hasModel', 'fedora-model' => 'info:fedora/fedora-system:def/model#')
    raise Unmapped if has_model_nodes.empty?

    model = has_model_nodes.first['rdf:resource']
    case model
    when 'info:fedora/afmodel:Dor_Collection'
      Dor::Collection
    when 'info:fedora/afmodel:Dor_AdminPolicyObject'
      Dor::AdminPolicyObject
    when 'info:fedora/afmodel:Dor_Item', 'info:fedora/dor:googleScannedBook', 'info:fedora/afmodel:Hydrus_Item'
      Dor::Item
    else
      raise Unmapped
    end
  end
end
