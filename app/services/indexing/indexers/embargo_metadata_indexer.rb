# frozen_string_literal: true

module Indexing
  module Indexers
    # Indexes the embargo metadata
    class EmbargoMetadataIndexer
      attr_reader :cocina

      def initialize(cocina:, **)
        @cocina = cocina
      end

      # These fields are used by the EmbargoReleaseService in dor-services-app
      # @return [Hash] the partial solr document for embargoMetadata
      def to_solr
        return {} if embargo_release_date.blank?

        {
          'embargo_status_ssim' => ['embargoed'],
          'embargo_release_dtpsimdv' => [embargo_release_date.utc.iso8601],
          'formatted_embargo_release_ss' => Indexing::Builders::FormattedDateBuilder.build(embargo_release_date)
        }
      end

      private

      def embargo_release_date
        cocina.access&.embargo&.releaseDate
      end
    end
  end
end
