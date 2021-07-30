# frozen_string_literal: true

module Cocina
  module ToDatacite
    # Transform the Cocina::Models::Description subjects attributes to the DataCite subjects attributes
    #  see https://support.datacite.org/reference/dois-2#put_dois-id
    class Subject
      # @param [Cocina::Models::Description] cocina_desc
      # @return [Hash] Hash of DataCite subjects attributes, conforming to the expectations of HTTP PUT request to DataCite
      def self.subjects_attributes(cocina_desc)
        new(cocina_desc).subjects_attributes
      end

      def initialize(cocina_desc)
        @cocina_desc = cocina_desc
      end

      # @return [Hash] Hash of DataCite subjects attributes, conforming to the expectations of HTTP PUT request to DataCite
      def subjects_attributes
        return [] if cocina_desc&.subject.blank?

        results = cocina_desc.subject.map do |cocina_subject|
          subject(cocina_subject)
        end
        results.compact
      end

      private

      attr :cocina_desc

      def subject(cocina_subject)
        return if cocina_subject.blank?

        if fast?(cocina_subject)
          fast_subject(cocina_subject)
        else
          non_fast_subject(cocina_subject)
        end
      end

      def fast_subject(cocina_subject)
        {
          subjectScheme: 'fast',
          schemeURI: 'http://id.worldcat.org/fast/'

        }.tap do |attribs|
          attribs[:subject] = cocina_subject.value if cocina_subject.value.present?
          attribs[:valueURI] = cocina_subject.uri if cocina_subject.uri.present?
        end
      end

      def non_fast_subject(cocina_subject)
        return if cocina_subject.value.blank?

        { subject: cocina_subject.value }
      end

      def fast?(cocina_subject)
        cocina_subject&.source&.code == 'fast'
      end
    end
  end
end
