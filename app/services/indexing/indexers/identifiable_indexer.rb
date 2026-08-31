# frozen_string_literal: true

module Indexing
  module Indexers
    # Indexes the druid, metadata sources, and related object titles
    class IdentifiableIndexer
      attr_reader :cocina

      CURRENT_CATALOG_TYPE = 'folio'

      def initialize(cocina:, **)
        @cocina = cocina
      end

      ## Module-level variable, shared between ALL mixin includers (and ALL *their* includers/extenders)!
      ## used for caching related object titles
      @@title_hash = {} # rubocop:disable Style/ClassVars

      # @return [Hash] the partial solr document for identifiable concerns
      def to_solr # rubocop:disable Metrics/AbcSize
        {}.tap do |solr_doc|
          # Hydrus APOs are excluded since every Hydrus item had its own APO.
          solr_doc['apo_title_ssimdv'] = [apo_title] unless hydrus_apo?

          if cocina.admin_policy?
            solr_doc['agreement_ssi'] = agreement_druid
            solr_doc['agreement_ssidv'] = title_for(agreement_druid)
          end
          solr_doc['metadata_source_ssimdv'] = identity_metadata_sources unless cocina.admin_policy?
          solr_doc['druid_prefixed_ssi'] = cocina.externalIdentifier
          solr_doc['druid_bare_ssi'] = cocina.externalIdentifier.delete_prefix('druid:')
        end
      end

      # Clears out the cache of related object titles. Used primarily in testing.
      def self.reset_cache!
        @@title_hash = {} # rubocop:disable Style/ClassVars
      end

      private

      # @return [Array<String>] calculated values for Solr index
      def identity_metadata_sources
        return ['DOR'] if !cocina.identification.respond_to?(:catalogLinks) || distinct_current_catalog_types.empty?

        distinct_current_catalog_types.map(&:capitalize)
      end

      def distinct_current_catalog_types
        # Filter out e.g. "previous symphony", "previous folio"
        @distinct_current_catalog_types ||=
          cocina.identification
                .catalogLinks
                .map(&:catalog)
                .uniq
                .sort
                .select { |catalog_type| catalog_type == CURRENT_CATALOG_TYPE }
      end

      def apo_druid
        cocina.administrative.hasAdminPolicy
      end

      def apo_title
        title_for(apo_druid)
      end

      def agreement_druid
        cocina.administrative.hasAgreement
      end

      # Populate the related object title cache if necessary.
      def title_for(druid)
        @@title_hash[druid] ||= begin
          object = CocinaObjectStore.find(druid)
          Cocina::Models::Builders::TitleBuilder.build(object.description.title)
        rescue CocinaObjectStore::CocinaObjectStoreError
          Honeybadger.notify("Bad association found on #{cocina.externalIdentifier}. #{druid} could not be found")
          druid
        end
      end

      def hydrus_apo?
        AdministrativeTags.for(identifier: apo_druid).include?('Project : Hydrus')
      end
    end
  end
end
