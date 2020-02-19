# frozen_string_literal: true

module Cocina
  # builds the Structural subschema for Cocina::Models::DRO from a Dor::Item
  class DroStructuralBuilder
    def self.build(item)
      new(item).build
    end

    def initialize(item)
      @item = item
    end

    def build
      {}.tap do |structural|
        case item.content_type_tag
        when 'Image (ltr)'
          structural[:hasMemberOrders] = [{ viewingDirection: 'left-to-right' }]
        when 'Image (rtl)'
          structural[:hasMemberOrders] = [{ viewingDirection: 'right-to-left' }]
        end

        structural[:contains] = build_filesets(item.contentMetadata, version: item.current_version, id: item.pid) unless item.is_a?(Dor::Etd) || item.contentMetadata.new?
      end
    end

    private

    attr_reader :item

    def build_filesets(content_metadata_ds, version:, id:)
      content_metadata_ds.ng_xml.xpath('//resource').map do |resource_node|
        files = build_files(resource_node.xpath('file'), version: version, parent_id: id)
        structural = {}
        structural[:contains] = files if files.present?
        Cocina::Models::FileSet.new(
          externalIdentifier: resource_node['id'],
          type: Cocina::Models::Vocab.fileset,
          label: resource_node.xpath('label').text,
          version: version,
          structural: structural
        )
      end
    end

    def build_files(file_nodes, version:, parent_id:)
      file_nodes.map do |node|
        Cocina::Models::File.new(
          externalIdentifier: "#{parent_id}/#{node['id']}",
          type: Cocina::Models::Vocab.file,
          label: node['id'],
          version: version
        )
      end
    end
  end
end
