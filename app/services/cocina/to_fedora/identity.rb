# frozen_string_literal: true

module Cocina
  module ToFedora
    # This transforms the cocina identification information to the Fedora 3 data model identityMetadata
    class Identity
      # @param [Dor::Item,Dor::Collection,Dor::Etd,Dor::AdminPolicyObject] fedora_object
      # @param [String] label the label for the cocina object.
      # @param [String] agreement_id (nil) the identifier for the agreement. Note that only apos and items may have an agreement.
      def self.apply(fedora_object, label:, agreement_id: nil)
        fedora_object.objectId = fedora_object.pid
        fedora_object.objectCreator = 'DOR'
        # Label may have already been set when setting descriptive metadata.
        fedora_object.objectLabel = label if fedora_object.objectLabel.empty?
        fedora_object.objectType = fedora_object.object_type # This comes from the class definition in dor-services
        fedora_object.identityMetadata.agreementId = agreement_id if agreement_id
      end
    end
  end
end
