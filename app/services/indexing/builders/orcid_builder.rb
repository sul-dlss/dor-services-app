# frozen_string_literal: true

module Indexing
  module Builders
    # Helper methods for working with Orcid in Cocina
    class OrcidBuilder
      # NOTE: there is similar code in orcid_client which fetches
      # ORCIDs out of cocina.  Consider consolidating at some point or keeping in sync.
      # see https://github.com/sul-dlss/orcid_client/blob/main/lib/sul_orcid_client/cocina_support.rb
      # and https://github.com/sul-dlss/dor_indexing_app/issues/1022

      # @param [Array<Cocina::Models::Contributor>] contributors
      # @return [String] the list of contributor ORCIDs to index into solr
      def self.build(contributors)
        new(contributors).build
      end

      def initialize(contributors)
        @contributors = Array(contributors)
      end

      def build
        contributors.filter_map { |contributor| SulOrcidClient::CocinaSupport.orcidid(contributor) }
      end

      private

      attr_reader :contributors
    end
  end
end
