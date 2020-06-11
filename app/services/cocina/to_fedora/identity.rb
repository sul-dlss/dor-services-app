# frozen_string_literal: true

module Cocina
  module ToFedora
    # This transforms the DRO.access schema to the
    # Fedora 3 data model identityMetadata
    class Identity
      def self.apply(obj, item, object_type)
        item.objectId = item.pid
        item.objectCreator = 'DOR'
        # May have already been set when setting descriptive metadata.
        item.objectLabel = obj.label if item.objectLabel.empty?
        item.objectType = object_type
        # Not currently mapping other ids.
      end
    end
  end
end
