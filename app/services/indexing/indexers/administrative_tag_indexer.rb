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
      def to_solr # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        administrative_tags.each do |tag|
          tag_prefix, rest = tag.strip.split(TAG_PART_DELIMITER_REGEX, 2)

          solr_doc['tag_ssim'] << tag # for Argo display and fq
          solr_doc['tag_text_unstemmed_im'] << tag # for Argo search

          # exploded tags are for hierarchical facets in Argo
          if explode_tag?(tag_prefix)
            explode_tag_hierarchy(tag: tag, field: 'exploded_nonproject_tag_ssimdv')
            explode_tag_hierarchy(tag: tag, field: 'hierarchical_other_tag_ssimdv', as_hierarchical: true)
          end

          next if rest.blank?

          if project_tag?(tag_prefix)
            explode_tag_hierarchy(tag: rest, field: 'exploded_project_tag_ssimdv')
            explode_tag_hierarchy(tag: rest, field: 'hierarchical_project_tag_ssimdv', as_hierarchical: true)
          end
          add_tag_type_specific_field(tag_prefix:, rest:)
        end
        solr_doc
      end

      private

      def solr_doc
        @solr_doc ||= {
          'tag_ssim' => [],
          'tag_text_unstemmed_im' => [],
          'exploded_nonproject_tag_ssimdv' => []
        }
      end

      # index each possible path, inclusive of the full tag.
      # e.g., for "A : B : C", return ["A",  "A : B",  "A : B : C"].
      # When as_hierarchical is true, return ["1|A|+",  "2|A : B|+",  "3|A : B : C|-"].
      # (The initial number is the level in the hierarchy, and the final character is
      # a marker for whether it's a leaf node or a branch node.)
      # this is for the blacklight-hierarchy plugin for faceting on each level of the hierarchy
      def explode_tag_hierarchy(tag:, field:, as_hierarchical: false)
        tag_parts = tag.split(TAG_PART_DELIMITER)
        solr_doc[field] ||= []

        1.upto(tag_parts.count).each do |i|
          joined_parts = tag_parts.take(i).join(TAG_PART_DELIMITER)
          solr_doc[field] << if as_hierarchical
                               leaf_or_branch_indicator = i == tag_parts.count ? '-' : '+'
                               "#{i}|#{joined_parts}|#{leaf_or_branch_indicator}"
                             else
                               joined_parts
                             end
        end
      end

      def add_tag_type_specific_field(tag_prefix:, rest:)
        return if ['Project', 'Registered By', 'Ticket'].exclude?(tag_prefix)

        prefix = tag_prefix.downcase.gsub(/\s/, '_')
        (solr_doc["#{prefix}_tag_ssim"] ||= []) << rest
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
