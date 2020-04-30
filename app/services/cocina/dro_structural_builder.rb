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
        case AdministrativeTags.content_type(item: item).first
        when 'Book (ltr)'
          structural[:hasMemberOrders] = [{ viewingDirection: 'left-to-right' }]
        when 'Book (rtl)'
          structural[:hasMemberOrders] = [{ viewingDirection: 'right-to-left' }]
        end

        structural[:contains] = build_filesets(item.contentMetadata, version: item.current_version.to_i, id: item.pid) unless item.contentMetadata.new?
        structural[:hasAgreement] = item.identityMetadata.agreementId.first unless item.identityMetadata.agreementId.empty?
        structural[:isMemberOf] = item.collection_ids.first if item.collection_ids.present?
      end
    end

    private

    attr_reader :item

    def build_filesets(content_metadata_ds, version:, id:)
      content_metadata_ds.ng_xml.xpath('//resource').map.with_index(1) do |resource_node, index|
        files = build_files(resource_node.xpath('file'), version: version, parent_id: id)
        structural = {}
        structural[:contains] = files if files.present?
        {
          externalIdentifier: resource_node['id'] || "#{id}_#{index}",
          type: Cocina::Models::Vocab.fileset,
          version: version,
          structural: structural
        }.tap do |attrs|
          label = resource_node.xpath('label').text
          # Use external identifier if label blank (which it is at least for some WAS Crawls).
          attrs[:label] = label.presence || attrs[:externalIdentifier]
        end
      end
    end

    def build_files(file_nodes, version:, parent_id:)
      file_nodes.map do |node|
        height = node.xpath('imageData/@height').text.presence&.to_i
        width = node.xpath('imageData/@width').text.presence&.to_i
        {
          externalIdentifier: "#{parent_id}/#{node['id']}",
          type: Cocina::Models::Vocab.file,
          label: node['id'],
          filename: node['id'],
          size: node['size'].to_i,
          version: version,
          hasMessageDigests: [],
          access: { access: node['publish'] == 'yes' ? 'world' : 'dark' },
          administrative: {
            sdrPreserve: node['preserve'] == 'yes',
            shelve: node['shelve'] == 'yes'
          }
        }.tap do |attrs|
          # Files from Goobi and Hydrus don't have mimetype until they hit exif-collect in the assemblyWF
          attrs[:hasMimeType] = node['mimetype'] if node['mimetype']
          attrs[:presentation] = { height: height, width: width } if height && width
          # The old google books use upcased versions. See https://argo.stanford.edu/view/druid:dd116zh0343
          # Web archive crawls use SHA1
          sha1 = node.xpath('checksum[@type="sha1" or @type="SHA1" or @type="SHA-1"]').text.presence
          attrs[:hasMessageDigests] << { type: 'sha1', digest: sha1 } if sha1
          md5 = node.xpath('checksum[@type="md5" or @type="MD5"]').text.presence
          attrs[:hasMessageDigests] << { type: 'md5', digest: md5 } if md5
        end
      end
    end
  end
end
