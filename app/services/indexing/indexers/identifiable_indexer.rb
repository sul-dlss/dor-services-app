# frozen_string_literal: true

module Indexing
  module Indexers
    # Indexes the druid, metadata sources, and the apo titles
    class IdentifiableIndexer
      attr_reader :cocina

      CURRENT_CATALOG_TYPE = 'folio'

      def initialize(cocina:, **)
        @cocina = cocina
      end

      ## Module-level variable, shared between ALL mixin includers (and ALL *their* includers/extenders)!
      ## used for caching apo titles
      @@apo_hash = {} # rubocop:disable Style/ClassVars

      # @return [Hash] the partial solr document for identifiable concerns
      def to_solr
        {}.tap do |solr_doc|
          add_apo_titles(solr_doc, cocina.administrative.hasAdminPolicy)

          unless cocina.is_a? Cocina::Models::AdminPolicyWithMetadata
            solr_doc['metadata_source_ssim'] =
              identity_metadata_sources
          end
          solr_doc['druid_prefixed_ssi'] = cocina.externalIdentifier
          solr_doc['druid_bare_ssi'] = cocina.externalIdentifier.delete_prefix('druid:')
        end
      end

      # Clears out the cache of apos. Used primarily in testing.
      def self.reset_cache!
        @@apo_hash = {} # rubocop:disable Style/ClassVars
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

      # @param [Hash] solr_doc
      # @param [String] admin_policy_id
      def add_apo_titles(solr_doc, admin_policy_id) # rubocop:disable Metrics/AbcSize
        row = populate_cache(admin_policy_id)
        title = row['related_obj_title']
        if row['is_from_hydrus']
          solr_doc['hydrus_apo_title_ssim'] ||= []
          solr_doc['hydrus_apo_title_ssim'] << title
        else
          solr_doc['nonhydrus_apo_title_ssim'] ||= [] # TODO: Remove
          solr_doc['nonhydrus_apo_title_ssim'] << title # TODO: Remove
          solr_doc['nonhydrus_apo_title_ssimdv'] ||= []
          solr_doc['nonhydrus_apo_title_ssimdv'] << title
        end
        solr_doc['apo_title_ssim'] ||= []
        solr_doc['apo_title_ssim'] << title
      end

      # populate cache if necessary
      def populate_cache(rel_druid)
        @@apo_hash[rel_druid] ||= begin
          related_obj = CocinaObjectStore.find(rel_druid)
          # APOs don't have projects, and since Hydrus is set to be retired, I don't want to
          # add the cocina property. Just check the tags service instead.
          is_from_hydrus = hydrus_tag?(rel_druid)
          title = Cocina::Models::Builders::TitleBuilder.build(related_obj.description.title)
          { 'related_obj_title' => title, 'is_from_hydrus' => is_from_hydrus }
        rescue CocinaObjectStore::CocinaObjectStoreError
          Honeybadger.notify("Bad association found on #{cocina.externalIdentifier}. #{rel_druid} could not be found")
          # This may happen if the given APO or Collection does not exist (bad data)
          { 'related_obj_title' => rel_druid, 'is_from_hydrus' => false }
        end
      end

      def hydrus_tag?(id)
        AdministrativeTags.for(identifier: id).include?('Project : Hydrus')
      end
    end
  end
end
