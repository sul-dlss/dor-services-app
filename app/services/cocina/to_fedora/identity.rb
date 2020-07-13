# frozen_string_literal: true

module Cocina
  module ToFedora
    # This transforms the DRO.access schema to the
    # Fedora 3 data model identityMetadata
    class Identity
      # @param [String] agreement_id (nil) the identifier for the agreement. Note that only items have an agreement.
      def self.apply(obj, item, object_type:, agreement_id: nil)
        item.objectId = item.pid
        item.objectCreator = 'DOR'
        # May have already been set when setting descriptive metadata.
        item.objectLabel = obj.label if item.objectLabel.empty?
        item.objectType = object_type
        item.identityMetadata.agreementId = agreement_id if agreement_id
      end
    end
  end
end
