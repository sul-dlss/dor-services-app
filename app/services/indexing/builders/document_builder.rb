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

      def self.for(...)
        new(...).for
      end

      # Optional parameters allow passing in pre-fetched data to avoid redundant lookups.
      # If an optional parameter is not provided, it will be fetched as needed.
      def initialize(model:, workflows: nil, parent_collections: nil, parent_collections_release_tags: nil, # rubocop:disable Metrics/ParameterLists
                     milestones: nil, release_tags: nil, trace_id: SecureRandom.uuid)
        @model = model
        @workflows = workflows
        @parent_collections = parent_collections
        @parent_collections_release_tags = parent_collections_release_tags
        @release_tags = release_tags
        @milestones = milestones
        @trace_id = trace_id
      end

      # @param [Cocina::Models::DROWithMetadata,Cocina::Models::CollectionWithMetadata,Cocina::Model::AdminPolicyWithMetadata] model # rubocop:disable Layout/LineLength
      def for # rubocop:disable Metrics/AbcSize
        indexer_for_type(model.type).new(id: druid,
                                         cocina: model,
                                         workflows:,
                                         parent_collections:,
                                         parent_collections_release_tags:,
                                         administrative_tags:,
                                         release_tags:,
                                         milestones:,
                                         trace_id:)
      rescue StandardError => e
        Honeybadger.notify('[DATA ERROR] Unexpected indexing exception',
                           tags: 'data_error',
                           error_message: e.message,
                           backtrace: e.backtrace,
                           context: { druid: })
        raise e
      end

      private

      attr_reader :model, :trace_id

      def druid
        model.externalIdentifier
      end

      def indexer_for_type(type)
        INDEXERS.fetch(type, ITEM_INDEXER)
      end

      def administrative_tags
        AdministrativeTags.for(identifier: druid)
      end

      def parent_collections
        @parent_collections ||= parent_collection_druids.filter_map do |collection_druid|
          CocinaObjectStore.find(collection_druid)
        rescue CocinaObjectStore::CocinaObjectStoreError
          Honeybadger.notify("Bad association found on #{druid}. #{collection_druid} could not be found")
          # This may happen if the referenced Collection does not exist (bad data)
          nil
        end
      end

      def milestones
        @milestones ||= Workflow::LifecycleService.milestones(druid:)
      end

      def parent_collections_release_tags
        @parent_collections_release_tags ||= parent_collection_druids.index_with do |collection_druid|
          ReleaseTagService.tags(druid: collection_druid)
        end
      end

      def release_tags
        @release_tags ||= ReleaseTagService.tags(druid:)
      end

      def parent_collection_druids
        return [] unless model.dro?

        model.structural.isMemberOf
      end

      # @return [Array<Workflow::WorkflowResponse>]
      def workflows
        @workflows ||= Workflow::Service.workflows(druid:)
      end
    end
  end
end
