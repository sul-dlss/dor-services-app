# frozen_string_literal: true

require 'dry/monads/maybe'

class DocumentBuilder
  ADMIN_POLICY_INDEXER = CompositeIndexer.new(
    AdministrativeTagIndexer,
    DataIndexer,
    RoleMetadataIndexer,
    DefaultObjectRightsIndexer,
    IdentityMetadataIndexer,
    DescriptiveMetadataIndexer,
    IdentifiableIndexer,
    WorkflowsIndexer
  )

  COLLECTION_INDEXER = CompositeIndexer.new(
    AdministrativeTagIndexer,
    DataIndexer,
    RightsMetadataIndexer,
    IdentityMetadataIndexer,
    DescriptiveMetadataIndexer,
    IdentifiableIndexer,
    ReleasableIndexer,
    WorkflowsIndexer
  )

  ITEM_INDEXER = CompositeIndexer.new(
    AdministrativeTagIndexer,
    DataIndexer,
    RightsMetadataIndexer,
    IdentityMetadataIndexer,
    DescriptiveMetadataIndexer,
    EmbargoMetadataIndexer,
    ContentMetadataIndexer,
    IdentifiableIndexer,
    CollectionTitleIndexer,
    ReleasableIndexer,
    WorkflowsIndexer
  )

  INDEXERS = {
    Cocina::Models::ObjectType.agreement => ITEM_INDEXER, # Agreement uses same indexer as item
    Cocina::Models::ObjectType.admin_policy => ADMIN_POLICY_INDEXER,
    Cocina::Models::ObjectType.collection => COLLECTION_INDEXER
  }.freeze

  @@parent_collections = {} # rubocop:disable Style/ClassVars

  def self.for(model:)
    new(model:).for
  end

  def self.reset_parent_collections
    @@parent_collections = {} # rubocop:disable Style/ClassVars
  end

  def initialize(model:)
    @model = model
  end

  # @param [Cocina::Models::DROWithMetadata,Cocina::Models::CollectionWithMetadata,Cocina::Model::AdminPolicyWithMetadata] model
  def for
    Rails.logger.debug { "Fetching indexer for #{model.type}" }
    indexer_for_type(model.type).new(id:,
                                     cocina: model,
                                     parent_collections:,
                                     administrative_tags:)
  end

  private

  attr_reader :model

  def id
    model.externalIdentifier
  end

  def indexer_for_type(type)
    INDEXERS.fetch(type, ITEM_INDEXER)
  end

  def parent_collections
    return [] unless model.dro?

    Array(model.structural&.isMemberOf).filter_map do |rel_druid|
      @@parent_collections[rel_druid] ||= Dor::Services::Client.object(rel_druid).find
    rescue Dor::Services::Client::UnexpectedResponse, Dor::Services::Client::NotFoundResponse
      Honeybadger.notify("Bad association found on #{model.externalIdentifier}. #{rel_druid} could not be found")
      # This may happen if the referenced Collection does not exist (bad data)
      nil
    end
  end

  def administrative_tags
    Dor::Services::Client.object(id).administrative_tags.list
  rescue Dor::Services::Client::NotFoundResponse
    []
  end
end
