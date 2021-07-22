# frozen_string_literal: true

module Cocina
  module ToDatacite
    # Transform the Cocina::Models::DROAccess attributes to the DataCite rightsList attributes
    #  see https://support.datacite.org/reference/dois-2#put_dois-id
    class DROAccess
      # @param [Cocina::Models::DROAccess] cocina_item_access
      # @return [Hash] Hash of DataCite rightsList attributes, conforming to the expectations of HTTP PUT request to DataCite
      def self.rights_list_attributes(cocina_item_access)
        new(cocina_item_access).rights_list_attributes
      end

      def initialize(cocina_item_access)
        @cocina_item_access = cocina_item_access
      end

      # @return [Hash] Hash of DataCite rightsList attributes, conforming to the expectations of HTTP PUT request to DataCite
      def rights_list_attributes
        return {} if cocina_item_access&.license.blank?

        {
          rights: cocina_item_access&.license
        }
      end

      private

      attr :cocina_item_access
    end
  end
end
