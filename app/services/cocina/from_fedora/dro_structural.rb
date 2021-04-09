# frozen_string_literal: true

module Cocina
  module FromFedora
    # builds the Structural subschema for Cocina::Models::DRO from a Dor::Item
    class DroStructural
      VIEWING_DIRECTION_FOR_CONTENT_TYPE = {
        'Book (ltr)' => 'left-to-right',
        'Book (rtl)' => 'right-to-left',
        'Book (flipbook, ltr)' => 'left-to-right',
        'Book (flipbook, rtl)' => 'right-to-left',
        'Manuscript (flipbook, ltr)' => 'left-to-right',
        'Manuscript (ltr)' => 'left-to-right'
      }.freeze

      def self.props(item, type:)
        new(item, type: type).props
      end

      def initialize(item, type:)
        @item = item
        @type = type
      end

      def props
        {}.tap do |structural|
          has_member_orders = build_has_member_orders
          structural[:hasMemberOrders] = has_member_orders if has_member_orders.present?

          contains = FileSets.build(item.contentMetadata, version: item.current_version.to_i, ignore_resource_type_errors: project_phoenix?)
          structural[:contains] = contains if contains.present?

          structural[:hasAgreement] = item.identityMetadata.agreementId.first unless item.identityMetadata.agreementId.empty?

          begin
            # Note that there is a bug with item.collection_ids that returns [] until item.collections is called. Below side-steps this.
            structural[:isMemberOf] = item.collections.map(&:id) if item.collections.present?
          rescue RSolr::Error::ConnectionRefused
            # ActiveFedora calls RSolr to lookup collections, but sometimes that call fails.
            raise SolrConnectionError, 'unable to connect to solr to resolve collections'
          end
        end
      end

      private

      attr_reader :item, :type

      delegate :stanford_only_downloadable_file?, :stanford_only_unrestricted_file?,
               :world_downloadable_file?, :world_unrestricted_file?, to: :rights_object


      def project_phoenix?
        AdministrativeTags.for(pid: item.id).include?('Google Book : GBS VIEW_FULL')
      end

      def rights_object
        item.rightsMetadata.dra_object
      end

      def build_has_member_orders
        member_orders = create_member_order if type == Cocina::Models::Vocab.book
        sequence = build_sequence(item.contentMetadata)
        if sequence.present?
          member_orders ||= [{}]
          member_orders.first[:members] = sequence
        end
        member_orders
      end

      def create_member_order
        reading_direction = item.contentMetadata.ng_xml.xpath('//bookData/@readingOrder').first&.value
        # See https://consul.stanford.edu/pages/viewpage.action?spaceKey=chimera&title=DOR+content+types%2C+resource+types+and+interpretive+metadata
        case reading_direction
        when 'ltr'
          [{ viewingDirection: 'left-to-right' }]
        when 'rtl'
          [{ viewingDirection: 'right-to-left' }]
        else
          # Fallback to using tags.  Some books don't have bookData nodes in contentMetadata XML.
          # When we migrate from Fedora 3, we don't need to look this up from AdministrativeTags
          content_type = AdministrativeTags.content_type(pid: item.id).first
          [{ viewingDirection: VIEWING_DIRECTION_FOR_CONTENT_TYPE[content_type] }] if VIEWING_DIRECTION_FOR_CONTENT_TYPE[content_type]
        end
      end

      # @return [Array<String>] the identifiers of files in a sequence for a virtual object
      def build_sequence(content_metadata_ds)
        content_metadata_ds.ng_xml.xpath('//resource/externalFile').map do |resource_node|
          "#{resource_node['resourceId']}/#{resource_node['fileId']}"
        end
      end

      def digests(node)
        [].tap do |digests|
          # The old google books use upcased versions. See https://argo.stanford.edu/view/druid:dd116zh0343
          # Web archive crawls use SHA1
          sha1 = node.xpath('checksum[@type="sha1" or @type="SHA1" or @type="SHA-1"]').text.presence
          digests << { type: 'sha1', digest: sha1 } if sha1
          md5 = node.xpath('checksum[@type="md5" or @type="MD5"]').text.presence
          digests << { type: 'md5', digest: md5 } if md5
        end
      end

      def build_files(file_nodes, version:, parent_id:)
        file_nodes.map do |node|
          height = node.xpath('imageData/@height').text.presence&.to_i
          width = node.xpath('imageData/@width').text.presence&.to_i
          use = node.xpath('@role').text.presence
          {
            externalIdentifier: "#{parent_id}/#{node['id']}",
            type: Cocina::Models::Vocab.file,
            label: node['id'],
            filename: node['id'],
            size: node['size'].to_i,
            version: version,
            hasMessageDigests: digests(node),
            access: access(node),
            administrative: {
              publish: node['publish'] == 'yes',
              sdrPreserve: node['preserve'] == 'yes',
              shelve: node['shelve'] == 'yes'
            }
          }.tap do |attrs|
            # Files from Goobi and Hydrus don't have mimetype until they hit exif-collect in the assemblyWF
            attrs[:hasMimeType] = node['mimetype'] if node['mimetype']
            attrs[:presentation] = { height: height, width: width } if height && width
            attrs[:use] = use if use
          end
        end
      end

      def access(node)
        # file_specific_rights = file_rights_for(node['id'])
        # item_rights_defaults.merge(file_specific_rights)
        if (file_specific_rights = file_rights_for(node['id']))
          byebug
          file_specific_rights
        else
          item_rights_defaults
        end
      end

      def file_rights_for(file_name)
        {}.tap do |file_rights|
          if world_unrestricted_file?(file_name)
            file_rights[:access] = 'world'
          elsif stanford_only_unrestricted_file?(file_name)
            file_rights[:access] = 'stanford'
          end

          if world_downloadable_file?(file_name)
            file_rights[:download] = 'world'
          elsif stanford_only_downloadable_file?(file_name)
            file_rights[:download] = 'stanford'
          end
        end.presence # drop?
      end

      def item_rights_defaults
        Access.props(item)
      end
    end
  end
end
