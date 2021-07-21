# frozen_string_literal: true

module Cocina
  module ToDatacite
    # Transform the Cocina::Models::Description title attributes to attributes for one DataCite title
    #  see https://support.datacite.org/reference/dois-2#put_dois-id
    class Title
      # @param [Cocina::Models::Description] cocina_desc
      # @return [Hash] Hash of attributes for one DataCite title, conforming to the expectations of HTTP PUT request to DataCite
      def self.title_attributes(cocina_desc)
        new(cocina_desc).title_attributes
      end

      def initialize(cocina_desc)
        @cocina_desc = cocina_desc
      end

      # @return [Hash] Hash of attributes for one DataCite title, conforming to the expectations of HTTP PUT request to DataCite
      def title_attributes
        return {} if cocina_desc&.title.blank?

        {}.tap do |attribs|
          attribs[:title] = title if title
        end
      end

      private

      attr :cocina_desc

      def title
        @title ||= cocina_desc.title&.first&.value
      end
    end
  end
end
