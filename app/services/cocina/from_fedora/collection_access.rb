# frozen_string_literal: true

module Cocina
  module FromFedora
    # builds the Access subschema for Collections
    class CollectionAccess < Access
      def self.props(rights_metadata_ds)
        new(rights_metadata_ds).props
      end

      def props
        super.tap do |props|
          # Collection access not include all props
          props.delete(:download)
          props.delete(:controlledDigitalLending)
          props.delete(:readLocation)
          props[:access] = 'world' unless props[:access] == 'dark'
        end
      end
    end
  end
end
