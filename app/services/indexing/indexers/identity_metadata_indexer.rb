# frozen_string_literal: true

module Indexing
  module Indexers
    # Indexes the identity metadata from cocina.identification
    class IdentityMetadataIndexer
      attr_reader :cocina_object

      def initialize(cocina:, **)
        @cocina_object = cocina
      end

      # @return [Hash] the partial solr document for identityMetadata
      def to_solr # rubocop:disable Metrics/AbcSize
        if object_type == 'adminPolicy' || cocina_object.identification.blank?
          return {
            'objectType_ssimdv' => [object_type]
          }
        end

        {
          'objectType_ssimdv' => [object_type],
          'identifier_ssim' => prefixed_identifiers, # sourceid, barcode, folio_instance_hrid for display
          'identifier_tesim' => prefixed_identifiers, # ditto ^^, for search, tokenized (can search prefix and value
          # as separate tokens)
          'barcode_id_ssimdv' => [barcode].compact,
          'source_id_ssi' => source_id, # for search and display (reports, track_sheet)
          'source_id_text_nostem_i' => source_id, # for search, tokenized per request from accessioneers
          'folio_instance_hrid_ssim' => [folio_instance_hrid].compact,
          'doi_ssimdv' => [doi].compact,
          'dissertation_id_ss' => dissertation_id
        }
      end

      private

      def source_id
        @source_id ||= cocina_object.identification.sourceId
      end

      def barcode
        @barcode ||= object_type == 'collection' ? nil : cocina_object.identification.barcode
      end

      def doi
        @doi ||= object_type == 'item' ? cocina_object.identification.doi : nil
      end

      def folio_instance_hrid
        @folio_instance_hrid ||= Array(cocina_object.identification.catalogLinks).find do |link|
          link.catalog == 'folio'
        end&.catalogRecordId
      end

      def object_type
        return 'adminPolicy' if cocina_object.admin_policy?
        return 'collection' if cocina_object.collection?
        return 'agreement' if agreement?
        return 'virtual object' if virtual_object?

        'item'
      end

      def agreement?
        cocina_object.type == Cocina::Models::ObjectType.agreement
      end

      def virtual_object?
        cocina_object.structural&.hasMemberOrders&.first&.members.present?
      end

      def prefixed_identifiers
        [].tap do |identifiers|
          identifiers << source_id if source_id
          identifiers << "barcode:#{barcode}" if barcode
          identifiers << "folio:#{folio_instance_hrid}" if folio_instance_hrid
        end
      end

      def dissertation_id
        @dissertation_id ||= dissertation_source_id? ? source_id.split(':').last : nil
      end

      def dissertation_source_id?
        source_id&.include?('dissertationid')
      end
    end
  end
end
