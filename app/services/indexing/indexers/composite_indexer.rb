# frozen_string_literal: true

module Indexing
  module Indexers
    # Allows Indexing::Builders::DocumentBuilder class (which builds the solr doc for an object) to be much more readable
    # Borrowed from https://github.com/samvera/valkyrie/blob/master/lib/valkyrie/persistence/solr/composite_indexer.rb
    class CompositeIndexer
      attr_reader :indexers

      def initialize(*indexers)
        @indexers = indexers
      end

      def new(**)
        Instance.new(indexers, **)
      end

      # Instance for a composite indexer
      class Instance
        attr_reader :indexers

        def initialize(indexers, **)
          @indexers = indexers.map do |i|
            i.new(**)
          rescue ArgumentError => e
            raise ArgumentError, "Unable to initialize #{i}. #{e.message}"
          end
        end

        # @return [Hash] the merged solr document for all the sub-indexers
        def to_solr
          indexers.map(&:to_solr).inject({}, &:merge)
        end
      end
    end
  end
end
