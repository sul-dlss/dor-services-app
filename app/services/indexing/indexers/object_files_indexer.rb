# frozen_string_literal: true

module Indexing
  module Indexers
    # Indexes the information about files in the object
    class ObjectFilesIndexer
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

      attr_reader :cocina

      def initialize(cocina:, **)
        @cocina = cocina
      end

      # @return [Hash] the partial solr document for files in the object
      def to_solr # rubocop:disable Metrics/AbcSize
        {
          'content_type_ssimdv' => type(cocina.type),
          'content_file_mimetypes_ssimdv' => files.map(&:hasMimeType).uniq,
          'content_file_count_itsi' => files.size,
          'shelved_content_file_count_itsi' => shelved_files.size,
          'resource_count_itsi' => file_sets.size,
          'preserved_size_dbtsi' => preserved_size, # double (trie) to support very large sizes
          'human_preserved_size_ss' => ActiveSupport::NumberHelper.number_to_human_size(preserved_size),
          'content_file_roles_ssimdv' => files.filter_map(&:use),
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
        @preserved_size ||= files.select { |file| file.administrative.sdrPreserve }
                                 .sum { |file| file.size || 0 }
      end

      def files
        @files ||= file_sets.flat_map { |fs| fs.structural.contains }
      end

      def file_sets
        @file_sets ||= Array(cocina.structural&.contains)
      end

      def type(object_type)
        TYPES.fetch(object_type, 'file')
      end
    end
  end
end
