# frozen_string_literal: true

class Indexer
  # @param [RSolr::Client] solr
  # @param [String] identifier for cocina object
  # @param [Integer] commit within milliseconds; if nil, then immediately committed.
  # @raise [Dor::Services::Client::NotFoundResponse]
  # @raise [Dor::Services::Client::UnexpectedResponse]
  # @return [Hash,Nil] solr document or nil if indexing failed
  def self.load_and_index(solr:, identifier:, commit_within: 1000)
    new(solr:, commit_within:).load_and_index(identifier:)
  end

  # @param [String] identifier for cocina object
  # @raise [Dor::Services::Client::NotFoundResponse]
  # @raise [Dor::Services::Client::UnexpectedResponse]
  # @return [Hash] solr document
  def self.load_and_build(identifier:)
    new(solr: nil).load_and_build(identifier:)
  end

  # @param [RSolr::Client] solr
  # @param [Cocina::Models::DROWithMetadata|CollectionWithMetadata|AdminPolicyWithMetadata] cocina object to index
  # @param [Integer] commit within milliseconds; if nil, then immediately committed.
  # @return [Hash,Nil] solr document or nil if indexing failed
  def self.reindex(solr:, cocina_with_metadata:, commit_within: 1000)
    new(solr:, commit_within:).reindex(cocina_with_metadata:)
  end

  # @param [RSolr::Client] solr
  # @param [String] identifier for cocina object
  # @param [Integer] commit within milliseconds; if nil, then immediately committed.
  # @return [Hash,Nil] solr document or nil if indexing failed
  def self.delete(solr:, identifier:, commit_within: 1000)
    new(solr:, commit_within:).delete(identifier:)
  end

  def initialize(solr:, commit_within: 1000)
    @solr = solr
    @commit_within = commit_within
  end

  def load(identifier:)
    Honeybadger.context({ identifier: })
    Dor::Services::Client.object(identifier).find
  end

  def build(cocina_with_metadata:)
    Honeybadger.context({ identifier: cocina_with_metadata.externalIdentifier })
    DocumentBuilder.for(model: cocina_with_metadata).to_solr
  end

  def load_and_build(identifier:)
    cocina_with_metadata = load(identifier:)
    build(cocina_with_metadata:)
  end

  def load_and_index(identifier:)
    Honeybadger.context({ identifier: })
    cocina_with_metadata = load(identifier:)
    reindex(cocina_with_metadata:)
  end

  # Indexes the provided Cocina object to solr
  def reindex(cocina_with_metadata:)
    Honeybadger.context({ identifier: cocina_with_metadata.externalIdentifier })

    solr_doc = build(cocina_with_metadata:)
    logger.debug 'solr doc created'
    solr.add(solr_doc, add_attributes: { commitWithin: commit_within || 1000 })
    solr.commit if commit_within.nil?

    logger.info "successfully updated index for #{cocina_with_metadata.externalIdentifier}"

    solr_doc
  end

  def delete(identifier:)
    solr.delete_by_id(identifier, commitWithin: commit_within || 1000)
    solr.commit if commit_within.nil?

    logger.info "successfully deleted #{identifier}"
  end

  private

  delegate :logger, to: :Rails
  attr_reader :solr, :commit_within
end
