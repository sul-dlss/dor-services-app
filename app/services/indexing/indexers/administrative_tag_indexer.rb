# frozen_string_literal: true

module Indexing
  module Indexers
    # Index administrative tags for an object
    class AdministrativeTagIndexer
      TAG_PART_DELIMITER = ' : '
      SPECIAL_TAG_TYPES_TO_INDEX = ['Project', 'Registered By'].freeze

      attr_reader :id, :administrative_tags

      def initialize(id:, administrative_tags:, **)
        @id = id
        @administrative_tags = administrative_tags
      end

      # @return [Hash] the partial solr document for administrative tags
      def to_solr # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/CyclomaticComplexity
        solr_doc = {
          'tag_ssim' => [],
          'tag_text_unstemmed_im' => [],
          'exploded_nonproject_tag_ssim' => []
        }
        administrative_tags.each do |tag|
          tag_prefix, rest = tag.split(TAG_PART_DELIMITER, 2)
          prefix = tag_prefix.downcase.strip.gsub(/\s/, '_')

          solr_doc['tag_ssim'] << tag # for Argo display and fq
          solr_doc['tag_text_unstemmed_im'] << tag # for Argo search

          # exploded tags are for hierarchical facets in Argo
          solr_doc['exploded_nonproject_tag_ssim'] += explode_tag_hierarchy(tag) unless prefix == 'project'

          next if rest.blank?

          # Index specific tag types that are used in Argo:
          #  project tags for search results and registered by tags for reports ...
          next unless SPECIAL_TAG_TYPES_TO_INDEX.include?(tag_prefix)

          (solr_doc["#{prefix}_tag_ssim"] ||= []) << rest.strip

          if prefix == 'project'
            solr_doc['exploded_project_tag_ssim'] ||= []
            solr_doc['exploded_project_tag_ssim'] += explode_tag_hierarchy(rest.strip)
          end
        end
        solr_doc
      end

      private

      # index each possible path, inclusive of the full tag.
      # e.g., for "A : B : C", return ["A",  "A : B",  "A : B : C"].
      # this is for the blacklight-hierarchy plugin for faceting on each level of the hierarchy
      def explode_tag_hierarchy(tag)
        tag_parts = tag.split(TAG_PART_DELIMITER)

        1.upto(tag_parts.count).map do |i|
          tag_parts.take(i).join(TAG_PART_DELIMITER)
        end
      end
    end
  end
end
