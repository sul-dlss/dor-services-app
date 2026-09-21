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
        return {} if titles.empty?

        {
          'collection_title_ssimdv' => titles,
          'collection_title_tesim' => titles,
          'collection_title_druid_ssimdv' => title_druids
        }
      end

      private

      # memoize an array of collection titles and druids, so we can iterate over them for different fields
      def titled_collections
        @titled_collections ||= parent_collections.filter_map do |collection_obj|
          title = Cocina::Models::Builders::TitleBuilder.build(collection_obj.description.title)
          [title, collection_obj.externalIdentifier] if title.present?
        end
      end

      # just the titles
      def titles
        titled_collections.map { |(title, _druid)| title }
      end

      # the composite title:druids
      def title_druids
        titled_collections.map do |(title, druid)|
          Indexing::CompositeFacetValue.build(label: title, druid:)
        end
      end
    end
  end
end
