# frozen_string_literal: true

module Cocina
  module ToFedora
    # This transforms the DRO.identification schema to the Fedora 3 data model identityMetadata
    class Identity
      # @param [String] agreement_id (nil) the identifier for the agreement. Note that only items have an agreement.
      def self.apply(item, label:, agreement_id: nil)
        item.objectId = item.pid
        item.objectCreator = 'DOR'
        # May have already been set when setting descriptive metadata.
        item.objectLabel = label if item.objectLabel.empty?
        item.objectType = item.object_type # This comes from the class definition in dor-services
        item.identityMetadata.agreementId = agreement_id if agreement_id
      end
    end
  end
end
