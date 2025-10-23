# frozen_string_literal: true

module Indexing
  module Indexers
    # Indexes the object's release tags
    class ReleasableIndexer
      # @param [Cocina::Models::DRO, Cocina::Models::Collection] cocina the cocina model to index
      # @param [Hash{String => Array<ReleaseTag>}] parent_collections_release_tags map of druid to release tags
      # @param [Array<ReleaseTag>] release_tags the release tags for the object
      def initialize(cocina:, parent_collections_release_tags:, release_tags:, **)
        @cocina = cocina
        @parent_collections_release_tags = parent_collections_release_tags
        @release_tags = release_tags
      end

      # @return [Hash] the partial solr document for releasable concerns
      def to_solr
        return {} if tags.blank? || Cocina::Support.dark?(cocina)

        {
          'released_to_ssim' => tags.map(&:to).uniq,
          'released_to_searchworks_dtpsidv' => searchworks_release_date,
          'released_to_earthworks_dtpsidv' => earthworks_release_date,
          'released_to_purl_sitemap_dtpsidv' => purl_sitemap_release_date
        }.compact
      end

      private

      attr_reader :cocina, :parent_collections_release_tags, :release_tags

      def purl_sitemap_release_date
        date_for_tag 'PURL sitemap'
      end

      def earthworks_release_date
        date_for_tag 'Earthworks'
      end

      def searchworks_release_date
        date_for_tag 'Searchworks'
      end

      def date_for_tag(project)
        tags.find { |tag| tag.to == project }&.date&.utc&.iso8601
      end

      # Item tags have precedence over collection tags, so if the collection is release=true
      # and the item is release=false, then it is not released
      # Note that this logic is duplicative of DSA's ReleaseTagService.for_public_metadata
      def tags
        @tags ||= tags_from_collection.merge(tags_from_item).values.select(&:release)
      end

      def collection_druids
        return [] unless cocina.dro?

        cocina.structural.isMemberOf
      end

      def tags_from_collection
        parent_collections_release_tags.values.each_with_object({}) do |collection_tags, result|
          collection_tags.select { |tag| tag.what == 'collection' }
                         .group_by(&:to).map do |project, releases_for_project|
            result[project] = releases_for_project.max_by(&:date)
          end
        end
      end

      def tags_from_item
        release_tags.group_by(&:to).transform_values do |releases_for_project|
          releases_for_project.max_by(&:date)
        end
      end
    end
  end
end
