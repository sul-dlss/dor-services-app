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

      def self.props(fedora_item, type:)
        new(fedora_item, type: type).props
      end

      def initialize(fedora_item, type:)
        @fedora_item = fedora_item
        @type = type
      end

      def props
        {}.tap do |structural|
          has_member_orders = build_has_member_orders
          structural[:hasMemberOrders] = has_member_orders if has_member_orders.present?

          # To build file sets, we need to consider both content metadata and
          # rights metadata, the latter of which is used to map file-specific
          # access/rights.
          contains = FileSets.build(fedora_item.contentMetadata,
                                    rights_metadata: fedora_item.rightsMetadata,
                                    version: fedora_item.current_version.to_i,
                                    ignore_resource_type_errors: project_phoenix?)
          structural[:contains] = contains if contains.present?

          structural[:hasAgreement] = fedora_item.identityMetadata.agreementId.first unless fedora_item.identityMetadata.agreementId.empty?

          begin
            # Note that there is a bug with fedora_item.collection_ids that returns [] until fedora_item.collections is called.
            # Below side-steps this.
            structural[:isMemberOf] = fedora_item.collections.map(&:id) if fedora_item.collections.present?
          rescue RSolr::Error::ConnectionRefused
            # ActiveFedora calls RSolr to lookup collections, but sometimes that call fails.
            raise SolrConnectionError, 'unable to connect to solr to resolve collections'
          end
        end
      end

      private

      attr_reader :fedora_item, :type

      def project_phoenix?
        AdministrativeTags.for(pid: fedora_item.id).include?('Google Book : GBS VIEW_FULL')
      end

      def build_has_member_orders
        member_orders = create_member_order if type == Cocina::Models::Vocab.book
        sequence = build_sequence(fedora_item.contentMetadata)
        if sequence.present?
          member_orders ||= [{}]
          member_orders.first[:members] = sequence
        end
        member_orders
      end

      def create_member_order
        reading_direction = fedora_item.contentMetadata.ng_xml.xpath('//bookData/@readingOrder').first&.value
        # See https://consul.stanford.edu/pages/viewpage.action?spaceKey=chimera&title=DOR+content+types%2C+resource+types+and+interpretive+metadata
        case reading_direction
        when 'ltr'
          [{ viewingDirection: 'left-to-right' }]
        when 'rtl'
          [{ viewingDirection: 'right-to-left' }]
        else
          # Fallback to using tags.  Some books don't have bookData nodes in contentMetadata XML.
          # When we migrate from Fedora 3, we don't need to look this up from AdministrativeTags
          content_type = AdministrativeTags.content_type(pid: fedora_item.id).first
          [{ viewingDirection: VIEWING_DIRECTION_FOR_CONTENT_TYPE[content_type] }] if VIEWING_DIRECTION_FOR_CONTENT_TYPE[content_type]
        end
      end

      # @return [Array<String>] the identifiers of files in a sequence for a virtual object
      def build_sequence(content_metadata_ds)
        content_metadata_ds.ng_xml.xpath('//resource/externalFile').map do |resource_node|
          "#{resource_node['resourceId']}/#{resource_node['fileId']}"
        end
      end
    end
  end
end
