# frozen_string_literal: true

module Indexing
  module Indexers
    # Indexes collection titles for an object
    class CollectionTitleIndexer
      attr_reader :cocina, :parent_collections

      def initialize(cocina:, parent_collections:, **)
        @cocina = cocina
        @parent_collections = parent_collections
      end

      # @return [Hash] the partial solr document for collection title concerns
      def to_solr
        {}.tap do |solr_doc|
          parent_collections.each do |collection_obj|
            coll_title = Cocina::Models::Builders::TitleBuilder.build(collection_obj.description.title)
            next if coll_title.blank?

            solr_doc['collection_title_ssimdv'] ||= []
            solr_doc['collection_title_ssimdv'] << coll_title
            solr_doc['collection_title_tesim'] ||= []
            solr_doc['collection_title_tesim'] << coll_title
          end
        end
      end
    end
  end
end
