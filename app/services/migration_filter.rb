# frozen_string_literal: true

# Determines if an object should be migrated.
class MigrationFilter
  # @return [boolean] true if should be migrated.
  def self.migrate?(rels_ext_ng_xml)
    new(rels_ext_ng_xml).migrate?
  end

  def initialize(rels_ext_ng_xml)
    @ng_xml = rels_ext_ng_xml
  end

  def migrate?
    return false if ng_xml.root.xpath('//fedora:conformsTo[@rdf:resource="info:fedora/afmodel:Part"]',
                                      'fedora' => 'info:fedora/fedora-system:def/relations-external#',
                                      'rdf' => 'http://www.w3.org/1999/02/22-rdf-syntax-ns#').present?

    return false if models.include?('info:fedora/afmodel:Part')
    return false if models.include?('info:fedora/afmodel:PermissionFile')

    true
  end

  private

  attr_reader :ng_xml, :fedora_object, :cocina_object

  def models
    @models ||= begin
      # Some items have incorrect RELS-EXT, no also checking info:fedora/fedora-system:def/relations-external#
      has_model_nodes = ng_xml.root.xpath('//fedora-model:hasModel',
                                          'fedora-model' => 'info:fedora/fedora-system:def/model#') + \
                        ng_xml.root.xpath('//fedora-model:hasModel',
                                          'fedora-model' => 'info:fedora/fedora-system:def/relations-external#')

      has_model_nodes.map do |has_model_node|
        has_model_node['rdf:resource']
      end
    end
  end
end
