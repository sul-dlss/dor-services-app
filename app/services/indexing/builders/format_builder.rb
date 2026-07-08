# frozen_string_literal: true

module Indexing
  module Builders
    # Helper methods for working with formats
    class FormatBuilder
      # @param [Array<Cocina::Models::DescriptiveValue>] forms
      # @return [Array<String>] the list of forms to index into solr
      def self.build(forms)
        new(forms).build
      end

      def initialize(forms)
        @forms = Array(forms)
      end

      def build # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/MethodLength
        formats = []
        formats << 'Archived website' if genre_includes?('Archived website')
        formats << 'Archive/Manuscript' if archive_manuscript?
        formats << 'Dataset' if lc_resource_type_includes?('Dataset') || genre_includes?(['dataset', 'data set'])
        formats << 'Image' if lc_resource_type_includes?('Still image') || mods_resource_type_includes?('still image')
        formats << 'Journal/Periodical' if genre_includes?('Periodicals')
        formats << 'Map' if lc_resource_type_includes?('Cartographic') || mods_resource_type_includes?('cartographic')
        formats << 'Music score' if notated_music?
        formats << 'Newspaper' if genre_includes?('Newspapers')
        formats << 'Object' if object?
        formats << 'Software/Multimedia' if software_multimedia?
        formats << 'Sound recording' if sound_recording?
        formats << 'Video/Film' if video_film?
        formats << 'Book' if book?

        formats << 'No format specified' if formats.empty?

        formats
      end

      private

      attr_reader :forms

      def archive_manuscript?
        lc_resource_type_includes?(['Collection', 'Manuscript', 'Mixed material']) ||
          mods_resource_type_includes?(['collection', 'manuscript', 'mixed material'])
      end

      def notated_music?
        lc_resource_type_includes?('Notated music') || mods_resource_type_includes?('Notated music')
      end

      def object?
        lc_resource_type_includes?('Artifact') || mods_resource_type_includes?('three dimensional object')
      end

      def software_multimedia?
        lc_resource_type_includes?(['Digital', 'Multimedia']) || mods_resource_type_includes?('software, multimedia')
      end

      def sound_recording?
        lc_resource_type_includes?('Audio') ||
          mods_resource_type_includes?(['sound recording', 'sound recording-musical', 'sound recording-nonmusical'])
      end

      def video_film?
        lc_resource_type_includes?('Moving image') || mods_resource_type_includes?('moving image')
      end

      def book?
        (lc_resource_type_includes?('Text') || mods_resource_type_includes?('text')) &&
          !genre_includes?(['Archived website', 'dataset', 'data set', 'Periodicals', 'Newspaper'])
      end

      def genres
        @genres ||= forms.filter_map { |form| form.value if form.type == 'genre' }.map(&:downcase)
      end

      def genre_includes?(genre_candidates)
        Array(genre_candidates).any? { |genre_candidate| genres.include?(genre_candidate.downcase) }
      end

      def lc_resource_types
        @lc_resource_types ||= forms.filter_map do |form|
          form.value&.downcase if resource_type?(form: form, source: 'LC Resource Types Scheme')
        end
      end

      def lc_resource_type_includes?(resource_type_candidates)
        Array(resource_type_candidates).any? do |resource_type_candidate|
          lc_resource_types.include?(resource_type_candidate.downcase)
        end
      end

      def mods_resource_types
        @mods_resource_types ||= forms.filter_map do |form|
          form.value&.downcase if resource_type?(form: form, source: 'MODS resource types')
        end
      end

      def mods_resource_type_includes?(resource_type_candidates)
        Array(resource_type_candidates).any? do |resource_type_candidate|
          mods_resource_types.include?(resource_type_candidate.downcase)
        end
      end

      def resource_type?(form:, source:)
        form.type == 'resource type' && form.source&.value == source
      end
    end
  end
end
