# frozen_string_literal: true

module Indexing
  module Builders
    # Helper methods for working with Orcid in Cocina
    class OrcidBuilder
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
