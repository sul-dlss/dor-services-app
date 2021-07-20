# frozen_string_literal: true

module Cocina
  module ToDatacite
    # Transform the Cocina::Models::Description note attributes to the DataCite descriptions attributes
    #  see https://support.datacite.org/reference/dois-2#put_dois-id
    class Note
      # @param [Cocina::Models::Description] cocina_desc
      # @return [Hash] Hash of DataCite descriptions attributes, conforming to the expectations of HTTP PUT request to DataCite
      def self.descriptions_attributes(cocina_desc)
        new(cocina_desc).descriptions_attributes
      end

      def initialize(cocina_desc)
        @cocina_desc = cocina_desc
      end

      # @return [Hash] Hash of DataCite descriptions attributes, conforming to the expectations of HTTP PUT request to DataCite
      def descriptions_attributes
        return {} if cocina_desc&.note.blank?

        {}.tap do |attribs|
          attribs[:description] = abstract if abstract
          attribs[:descriptionType] = 'Abstract' if abstract
        end
      end

      private

      attr :cocina_desc

      def abstract
        @abstract ||= cocina_desc.note.find { |cocina_note| cocina_note.type == 'abstract' }&.value
      end
    end
  end
end
