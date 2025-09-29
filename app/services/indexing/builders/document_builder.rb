# frozen_string_literal: true

module Indexing
  module Builders
    # Builds solr document for indexing.
    class DocumentBuilder
      ADMIN_POLICY_INDEXER = Indexing::Indexers::CompositeIndexer.new(
        Indexing::Indexers::AdministrativeTagIndexer,
        Indexing::Indexers::BasicIndexer,
        Indexing::Indexers::RoleMetadataIndexer,
        Indexing::Indexers::DefaultObjectRightsIndexer,
        Indexing::Indexers::IdentityMetadataIndexer,
        Indexing::Indexers::DescriptiveMetadataIndexer,
        Indexing::Indexers::IdentifiableIndexer,
        Indexing::Indexers::WorkflowsIndexer
      )

      COLLECTION_INDEXER = Indexing::Indexers::CompositeIndexer.new(
        Indexing::Indexers::AdministrativeTagIndexer,
        Indexing::Indexers::BasicIndexer,
        Indexing::Indexers::RightsMetadataIndexer,
        Indexing::Indexers::IdentityMetadataIndexer,
        Indexing::Indexers::DescriptiveMetadataIndexer,
        Indexing::Indexers::IdentifiableIndexer,
        Indexing::Indexers::ReleasableIndexer,
        Indexing::Indexers::WorkflowsIndexer
      )

      ITEM_INDEXER = Indexing::Indexers::CompositeIndexer.new(
        Indexing::Indexers::AdministrativeTagIndexer,
        Indexing::Indexers::BasicIndexer,
        Indexing::Indexers::RightsMetadataIndexer,
        Indexing::Indexers::IdentityMetadataIndexer,
        Indexing::Indexers::DescriptiveMetadataIndexer,
        Indexing::Indexers::EmbargoMetadataIndexer,
        Indexing::Indexers::ObjectFilesIndexer,
        Indexing::Indexers::IdentifiableIndexer,
        Indexing::Indexers::CollectionTitleIndexer,
        Indexing::Indexers::ReleasableIndexer,
        Indexing::Indexers::WorkflowsIndexer
      )

      INDEXERS = {
        Cocina::Models::ObjectType.agreement => ITEM_INDEXER, # Agreement uses same indexer as item
        Cocina::Models::ObjectType.admin_policy => ADMIN_POLICY_INDEXER,
        Cocina::Models::ObjectType.collection => COLLECTION_INDEXER
      }.freeze

      @@parent_collections = {} # rubocop:disable Style/ClassVars
      @@parent_collections_release_tags = {} # rubocop:disable Style/ClassVars

      def self.for(...)
        new(...).for
      end

      def self.reset_parent_collections
        @@parent_collections = {} # rubocop:disable Style/ClassVars
        @@parent_collections_release_tags = {} # rubocop:disable Style/ClassVars
      end

      def initialize(model:, workflows: nil, trace_id: SecureRandom.uuid)
        @model = model
        @workflows = workflows
        @trace_id = trace_id
      end

      # @param [Cocina::Models::DROWithMetadata,Cocina::Models::CollectionWithMetadata,Cocina::Model::AdminPolicyWithMetadata] model # rubocop:disable Layout/LineLength
      def for
        indexer_for_type(model.type).new(id:,
                                         cocina: model,
                                         workflows:,
                                         parent_collections:,
                                         administrative_tags:,
                                         parent_collections_release_tags:,
                                         trace_id:)
      rescue StandardError => e
        Honeybadger.notify('[DATA ERROR] Unexpected indexing exception',
                           tags: 'data_error',
                           error_message: e.message,
                           backtrace: e.backtrace,
                           context: { druid: id })
        raise e
      end

      private

      attr_reader :model, :workflow_client, :trace_id, :workflows

      def id
        model.externalIdentifier
      end

      def indexer_for_type(type)
        INDEXERS.fetch(type, ITEM_INDEXER)
      end

      def parent_collections
        return [] unless model.dro?

        Array(model.structural&.isMemberOf).filter_map do |rel_druid|
          @@parent_collections[rel_druid] ||= CocinaObjectStore.find(rel_druid)
        rescue CocinaObjectStore::CocinaObjectStoreError
          Honeybadger.notify("Bad association found on #{model.externalIdentifier}. #{rel_druid} could not be found")
          # This may happen if the referenced Collection does not exist (bad data)
          nil
        end
      end

      def parent_collections_release_tags
        parent_collections.each_with_object({}) do |collection, hash|
          @@parent_collections_release_tags[collection.externalIdentifier] ||= ReleaseTagService.item_tags(cocina_object: collection) # rubocop:disable Layout/LineLength
          hash[collection.externalIdentifier] = @@parent_collections_release_tags[collection.externalIdentifier]
        end
      end

      def administrative_tags
        AdministrativeTags.for(identifier: id)
      end
    end
  end
end
