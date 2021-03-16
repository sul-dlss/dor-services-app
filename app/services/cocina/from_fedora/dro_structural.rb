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

          contains = FileSets.build(item.contentMetadata, version: item.current_version.to_i)
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
    end
  end
end
