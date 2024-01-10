# frozen_string_literal: true

class ContentMetadataIndexer
  attr_reader :cocina

  def initialize(cocina:, **)
    @cocina = cocina
  end

  # @return [Hash] the partial solr document for contentMetadata
  def to_solr
    {
      'content_type_ssim' => type(cocina.type),
      'content_file_mimetypes_ssim' => files.map(&:hasMimeType).uniq,
      'content_file_count_itsi' => files.size,
      'shelved_content_file_count_itsi' => shelved_files.size,
      'resource_count_itsi' => file_sets.size,
      'preserved_size_dbtsi' => preserved_size, # double (trie) to support very large sizes
      'content_file_roles_ssim' => files.filter_map(&:use),
      # first_shelved_image is neither indexed nor multiple
      'first_shelved_image_ss' => first_shelved_image
    }
  end

  private

  def first_shelved_image
    shelved_files.find { |file| file.filename.end_with?('jp2') }&.filename
  end

  def shelved_files
    files.select { |file| file.administrative.shelve }
  end

  def preserved_size
    files.select { |file| file.administrative.sdrPreserve }
         .filter_map(&:size).sum # filter out missing size
  end

  def files
    @files ||= file_sets.flat_map { |fs| fs.structural.contains }
  end

  def file_sets
    @file_sets ||= Array(cocina.structural&.contains)
  end

  TYPES = {
    Cocina::Models::ObjectType.image => 'image',
    Cocina::Models::ObjectType.manuscript => 'image',
    Cocina::Models::ObjectType.book => 'book',
    Cocina::Models::ObjectType.map => 'map',
    Cocina::Models::ObjectType.three_dimensional => '3d',
    Cocina::Models::ObjectType.media => 'media',
    Cocina::Models::ObjectType.webarchive_seed => 'webarchive-seed',
    Cocina::Models::ObjectType.webarchive_binary => 'webarchive-binary',
    Cocina::Models::ObjectType.geo => 'geo',
    Cocina::Models::ObjectType.document => 'document'
  }.freeze

  def type(object_type)
    TYPES.fetch(object_type, 'file')
  end
end
