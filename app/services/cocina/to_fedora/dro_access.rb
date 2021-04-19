# frozen_string_literal: true

module Cocina
  module ToFedora
    # This transforms the DROAccess schema to the
    # Fedora 3 data model rightsMetadata
    class DROAccess < Access
      def apply
        EmbargoMetadataGenerator.generate(embargo: access.embargo, embargo_metadata: item.embargoMetadata) if access.embargo

        super
      end
    end
  end
end
