# frozen_string_literal: true

module Indexing
  module Indexers
    # Index administrative tags for an object
    class AdministrativeTagIndexer
      TAG_PART_DELIMITER_REGEX = /\s+:\s+/
      TAG_PART_DELIMITER = ' : '

      attr_reader :administrative_tags

      def initialize(administrative_tags:, **)
        @administrative_tags = administrative_tags
      end

      # @return [Hash] the partial solr document for administrative tags
      def to_solr # rubocop:disable Metrics/AbcSize
        administrative_tags.each do |tag|
          tag_prefix, rest = tag.strip.split(TAG_PART_DELIMITER_REGEX, 2)

          solr_doc['tag_ssim'] << tag # for Argo display and fq
          solr_doc['tag_text_unstemmed_im'] << tag # for Argo search
          solr_doc['tag_text_unstemmed_sim'] << tag # for advanced search

          # exploded tags are for hierarchical facets in Argo
          explode_tag_hierarchy(tag: tag, field: 'exploded_nonproject_tag_ssimdv') if explode_tag?(tag_prefix)

          next if rest.blank?

          explode_tag_hierarchy(tag: rest, field: 'exploded_project_tag_ssimdv') if project_tag?(tag_prefix)
          add_tag_type_specific_field(tag_prefix:, rest:)
        end
        solr_doc
      end

      private

      def solr_doc
        @solr_doc ||= {
          'tag_ssim' => [],
          'tag_text_unstemmed_im' => [],
          'tag_text_unstemmed_sim' => [],
          'exploded_nonproject_tag_ssimdv' => []
        }
      end

      # index each possible path, inclusive of the full tag.
      # e.g., for "A : B : C", return ["A",  "A : B",  "A : B : C"].
      # this is for the blacklight-hierarchy plugin for faceting on each level of the hierarchy
      def explode_tag_hierarchy(tag:, field:)
        tag_parts = tag.split(TAG_PART_DELIMITER)
        solr_doc[field] ||= []

        1.upto(tag_parts.count).each do |i|
          solr_doc[field] << tag_parts.take(i).join(TAG_PART_DELIMITER)
        end
      end

      def add_tag_type_specific_field(tag_prefix:, rest:)
        return if ['Project', 'Registered By', 'Ticket'].exclude?(tag_prefix)

        prefix = tag_prefix.downcase.gsub(/\s/, '_')
        (solr_doc["#{prefix}_tag_ssim"] ||= []) << rest
        (solr_doc["#{prefix}_tag_text_unstemmed_sim"] ||= []) << rest
      end

      def explode_tag?(tag_prefix)
        ['Project', 'Ticket'].exclude?(tag_prefix)
      end

      def project_tag?(tag_prefix)
        tag_prefix == 'Project'
      end
    end
  end
end
