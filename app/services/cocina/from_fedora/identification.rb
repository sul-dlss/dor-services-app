# frozen_string_literal: true

module Cocina
  module FromFedora
    # Creates Cocina::Identification object properties from Fedora objects
    class Identification
      # @param [Dor::Item,Dor::Collection,Dor::Etd] fedora_object
      # @return [Hash] a hash that can be mapped to a Cocina::Identification object
      # @raises [Mapper::MissingSourceID]
      def self.props(fedora_object)
        new(fedora_object).props
      end

      def initialize(fedora_object)
        @fedora_object = fedora_object
      end

      def props
        {
          sourceId: source_id,
          barcode: fedora_object.identityMetadata.barcode
        }.compact
      end

      private

      attr_reader :fedora_object

      def source_id
        if fedora_object.source_id
          fedora_object.source_id.strip.sub(/ *: */, ':')
        elsif fedora_object.is_a? Dor::Collection
          nil
        else
          # ETDs post Summer 2020 have a source id, but legacy ones don't.  In that case look for a dissertation_id.
          dissertation = fedora_object.otherId.find { |id| id.start_with?('dissertationid:') }
          raise Mapper::MissingSourceID, "unable to resolve a sourceId for #{fedora_object.pid}" unless dissertation

          dissertation
        end
      end
    end
  end
end
