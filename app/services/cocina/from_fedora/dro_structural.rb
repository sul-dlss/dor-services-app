# frozen_string_literal: true

module Cocina
  module FromFedora
    # builds the Structural subschema for Cocina::Models::DRO from a Dor::Item
    class DroStructural
      def self.props(fedora_item, type:, notifier:)
        new(fedora_item, type: type, notifier: notifier).props
      end

      def initialize(fedora_item, type:, notifier:)
        @fedora_item = fedora_item
        @type = type
        @notifier = notifier
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
                                    notifier: notifier)
          structural[:contains] = contains if contains.present?

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

      attr_reader :fedora_item, :type, :notifier

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
        viewing_direction = ViewingDirectionHelper.viewing_direction(druid: fedora_item.pid, content_ng_xml: fedora_item.contentMetadata.ng_xml)
        viewing_direction ||= 'left-to-right'

        [{ viewingDirection: viewing_direction }]
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
