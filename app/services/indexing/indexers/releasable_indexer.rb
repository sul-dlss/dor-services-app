# frozen_string_literal: true

module Indexing
  module Indexers
    # Indexes the object's release tags
    class ReleasableIndexer
      attr_reader :cocina, :parent_collections, :parent_collections_release_tags

      def initialize(cocina:, parent_collections:, parent_collections_release_tags:, **)
        @cocina = cocina
        @parent_collections = parent_collections
        @parent_collections_release_tags = parent_collections_release_tags
      end

      # @return [Hash] the partial solr document for releasable concerns
      def to_solr
        return {} if tags.blank?

        {
          'released_to_ssim' => tags.map(&:to).uniq,
          'released_to_searchworks_dttsi' => searchworks_release_date,
          'released_to_earthworks_dttsi' => earthworks_release_date,
          'released_to_purl_sitemap_dttsi' => purl_sitemap_release_date
        }.compact
      end

      private

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

      def tags_from_collection
        parent_collections_release_tags.values.each_with_object({}) do |collection_tags, result|
          collection_tags.select { |tag| tag.what == 'collection' }
                         .group_by(&:to).map do |project, releases_for_project|
            result[project] = releases_for_project.max_by(&:date)
          end
        end
        # parent_collections.each_with_object({}) do |collection, result|
        #   ReleaseTagService.item_tags(cocina_object: collection)
        #                    .select { |tag| tag.what == 'collection' }
        #                    .group_by(&:to).map do |project, releases_for_project|
        #     result[project] = releases_for_project.max_by(&:date)
        #   end
        # end
      end

      def tags_from_item
        ReleaseTagService.item_tags(cocina_object: cocina)
                         .group_by(&:to).transform_values do |releases_for_project|
          releases_for_project.max_by(&:date)
        end
      end
    end
  end
end
