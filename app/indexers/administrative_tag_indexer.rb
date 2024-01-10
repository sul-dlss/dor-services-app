# frozen_string_literal: true

# Index administrative tags for an object.
# NOTE: Most of this code was extracted from the dor-services gem:
#       https://github.com/sul-dlss/dor-services/blob/v9.0.0/lib/dor/datastreams/identity_metadata_ds.rb#L196-L218
class AdministrativeTagIndexer
  TAG_PART_DELIMITER = ' : '
  SPECIAL_TAG_TYPES_TO_INDEX = ['Project', 'Registered By'].freeze

  attr_reader :id

  def initialize(id:, administrative_tags:, **)
    @id = id
    @administrative_tags = administrative_tags
  end

  # @return [Hash] the partial solr document for administrative tags
  def to_solr # rubocop:disable Metrics/MethodLength
    Rails.logger.debug { "In #{self.class}" }

    solr_doc = {
      'tag_ssim' => [],
      'tag_text_unstemmed_im' => [],
      'exploded_nonproject_tag_ssim' => []
    }
    administrative_tags.each do |tag|
      tag_prefix, rest = tag.split(TAG_PART_DELIMITER, 2)
      prefix = tag_prefix.downcase.strip.gsub(/\s/, '_')

      solr_doc['tag_ssim'] << tag # for facet and display
      solr_doc['tag_text_unstemmed_im'] << tag # for search

      solr_doc['exploded_nonproject_tag_ssim'] += exploded_tags_from(tag) unless prefix == 'project'

      next if SPECIAL_TAG_TYPES_TO_INDEX.exclude?(tag_prefix) || rest.nil?

      (solr_doc["#{prefix}_tag_ssim"] ||= []) << rest.strip

      if prefix == 'project'
        solr_doc['exploded_project_tag_ssim'] ||= []
        solr_doc['exploded_project_tag_ssim'] += exploded_tags_from(rest.strip)
      end
    end
    solr_doc
  end

  private

  attr_reader :administrative_tags

  # solrize each possible prefix for the tag, inclusive of the full tag.
  # e.g., for a tag such as "A : B : C", this will solrize to an _ssim field
  # that contains ["A",  "A : B",  "A : B : C"].
  def exploded_tags_from(tag)
    tag_parts = tag.split(TAG_PART_DELIMITER)

    1.upto(tag_parts.count).map do |i|
      tag_parts.take(i).join(TAG_PART_DELIMITER)
    end
  end
end
