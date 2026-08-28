# frozen_string_literal: true

module Cocina
  module ToDatacite
    # Transform the Cocina::Models::DRO title attributes to attributes for one DataCite title
    #  see https://support.datacite.org/reference/dois-2#put_dois-id
    class Title
      # @param [Cocina::Models::DRO] cocina_object
      # @return [Array<Hash>] list of titles for DataCite, conforming to the expectations of HTTP PUT request
      # to DataCite
      def self.title_attributes(cocina_object)
        new(cocina_object).title_attributes
      end

      def initialize(cocina_object)
        @cocina_object = cocina_object
      end

      # @return [Array<Hash>] list of titles for DataCite, conforming to the expectations of HTTP PUT request
      # to DataCite
      def title_attributes
        [{ title: CocinaDisplay::CocinaRecord.new(cocina_object.to_h.with_indifferent_access).display_title }]
      end

      private

      attr_reader :cocina_object
    end
  end
end
