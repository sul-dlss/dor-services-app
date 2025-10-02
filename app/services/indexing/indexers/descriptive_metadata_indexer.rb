# frozen_string_literal: true

require 'stanford-mods'

module Indexing
  module Indexers
    # Indexes the descriptive metadata
    # rubocop:disable Metrics/ClassLength
    class DescriptiveMetadataIndexer
      # See https://github.com/sul-dlss/stanford-mods/blob/master/lib/stanford-mods/searchworks.rb#L244
      FORMAT = {
        'cartographic' => 'Map',
        'manuscript' => 'Archive/Manuscript',
        'mixed material' => 'Archive/Manuscript',
        'moving image' => 'Video',
        'notated music' => 'Music score',
        'software, multimedia' => 'Software/Multimedia',
        'sound recording-musical' => 'Music recording',
        'sound recording-nonmusical' => 'Sound recording',
        'sound recording' => 'Sound recording',
        'still image' => 'Image',
        'three dimensional object' => 'Object',
        'text' => 'Book'
      }.freeze

      attr_reader :cocina, :stanford_mods_record

      def initialize(cocina:, **)
        @cocina = cocina
        mods_ng = Cocina::Models::Mapping::ToMods::Description.transform(cocina.description, cocina.externalIdentifier)
        @stanford_mods_record = Stanford::Mods::Record.new.from_nk_node(mods_ng.root)
      end

      # @return [Hash] the partial solr document for descriptive metadata
      def to_solr # rubocop:disable Metrics/AbcSize
        {
          # title
          'main_title_tenim' => main_title, # for searching; 2 more field types are copyFields in solr schema.xml
          'full_title_tenim' => full_title, # for searching; 1 more field type is copyField in solr schema.xml
          'additional_titles_tenim' => additional_titles, # for searching; 1 more field type is copyField in
          # solr schema.xml
          'display_title_ss' => display_title, # for display in Argo

          # contributor
          'author_text_nostem_im' => author_primary, # primary author tokenized but not stemmed
          'author_display_ss' => author_primary, # used for author display in Argo
          'contributor_text_nostem_im' => author_all, # author names should be tokenized but not stemmed
          'contributor_orcids_ssim' => orcids, # TODO: Remove
          'contributor_orcids_ssimdv' => orcids,

          # topic
          'topic_ssim' => stanford_mods_record.topic_facet&.uniq,
          'topic_tesim' => stemmable_topics,

          # publication
          'originInfo_date_created_tesim' => creation_date,
          'originInfo_publisher_tesim' => publisher_name,
          'originInfo_place_placeTerm_tesim' => event_place, # do we want this?
          'sw_pub_date_facet_ssi' => stanford_mods_record.pub_year_int.to_s, # SW Date facet

          # SW facets plus a friend facet
          'sw_format_ssim' => sw_format, # TODO: Remove
          'sw_format_ssimdv' => sw_format, # SW Resource Type facet
          'mods_typeOfResource_ssim' => resource_type, # TODO: Remove
          'mods_typeOfResource_ssimdv' => resource_type, # MODS Resource Type facet
          'sw_genre_ssim' => stanford_mods_record.sw_genre, # TODO: Remove
          'sw_genre_ssimdv' => stanford_mods_record.sw_genre, # SW Genre facet
          'sw_language_ssim' => stanford_mods_record.sw_language_facet, # TODO: Remove
          'sw_language_ssimdv' => stanford_mods_record.sw_language_facet, # SW Language facet
          'sw_subject_temporal_ssim' => stanford_mods_record.era_facet, # SW Era facet
          'sw_subject_geographic_ssim' => subject_geographic, # TODO: Remove
          'sw_subject_geographic_ssimdv' => subject_geographic, # SW Region facet

          # all the descriptive data that we want to search on, with different flavors for better recall and precision
          'descriptive_tiv' => all_search_text, # ICU tokenized, ICU folded
          'descriptive_text_nostem_i' => all_search_text, # whitespace tokenized, ICU folded, word delimited
          'descriptive_teiv' => all_search_text # ICU tokenized, ICU folded, minimal stemming
        }.compact_blank
      end

      private

      def subject_temporal
        Indexing::Builders::TemporalBuilder.build(subjects)
      end

      def subject_geographic
        Indexing::Builders::GeographicBuilder.build(subjects)
      end

      def subjects
        @subjects ||= Array(cocina.description.subject)
      end

      def author_primary
        author_builder.build_primary
      end

      def author_all
        author_builder.build_all
      end

      def author_builder
        @author_builder ||= Indexing::Builders::AuthorBuilder.new(Array(cocina.description.contributor))
      end

      def orcids
        Indexing::Builders::OrcidBuilder.build(Array(cocina.description.contributor))
      end

      def main_title
        Cocina::Models::Builders::TitleBuilder.main_title(cocina.description.title)
      end

      def full_title
        Cocina::Models::Builders::TitleBuilder.full_title(cocina.description.title)
      end

      def additional_titles
        Cocina::Models::Builders::TitleBuilder.additional_titles(cocina.description.title)
      end

      def display_title
        Cocina::Models::Builders::TitleBuilder.build(cocina.description.title,
                                                     catalog_links: catalog_links)
      end

      def forms
        @forms ||= Array(cocina.description.form)
      end

      def resource_type
        @resource_type ||= forms.select do |form|
          form.source&.value == 'MODS resource types' &&
            %w[collection manuscript].exclude?(form.value)
        end.map(&:value)
      end

      # rubocop:disable Metrics/CyclomaticComplexity
      # rubocop:disable Metrics/PerceivedComplexity
      def sw_format # rubocop:disable Metrics/AbcSize
        return ['Map'] if resource_type?('software, multimedia') && resource_type?('cartographic')
        return ['Dataset'] if resource_type?('software, multimedia') && genre?('dataset')
        return ['Archived website'] if resource_type?('text') && genre?('archived website')
        return ['Book'] if resource_type?('text') && issuance?('monographic')
        if resource_type?('text') && (issuance?('continuing') || issuance?('serial') || frequency?)
          return ['Journal/Periodical']
        end

        resource_type_formats = flat_forms_for('resource type').map { |form| FORMAT[form.value&.downcase] }.uniq.compact
        resource_type_formats.delete('Book') if resource_type_formats.include?('Archive/Manuscript')

        return resource_type_formats if resource_type_formats == ['Book']

        genre_formats = flat_forms_for('genre').map { |form| form.value&.capitalize }.uniq

        (resource_type_formats + genre_formats).presence
      end

      # rubocop:enable Metrics/CyclomaticComplexity
      # rubocop:enable Metrics/PerceivedComplexity
      def resource_type?(type)
        flat_forms_for('resource type').any? { |form| form.value == type }
      end

      def genre?(genre)
        flat_forms_for('genre').any? { |form| form.value == genre }
      end

      def issuance?(issuance)
        flat_event_notes.any? { |note| note.type == 'issuance' && note.value == issuance }
      end

      def frequency?
        flat_event_notes.any? { |note| note.type == 'frequency' }
      end

      def flat_forms_for(type)
        forms.flat_map do |form|
          if form.type == type
            flat_value(form)
          else
            flat_value(form).select { |form_value| form_value.type == type }
          end
        end
      end

      def flat_event_notes
        @flat_event_notes ||= events.flat_map { |event| flat_event(event) }.flat_map do |event|
          Array(event.note).flat_map do |note|
            flat_value(note)
          end
        end
      end

      def pub_year
        Indexing::Selectors::PubYearSelector.build(events)
      end

      def creation_date
        @creation_date ||= Indexing::Builders::EventDateBuilder.build(creation_event, 'creation')
      end

      def event_place
        place_event = events.find { |event| event.type == 'publication' } || events.first
        Indexing::Builders::EventPlaceBuilder.build(place_event)
      end

      def publisher_name
        publish_events = events.map { |event| event.parallelEvent&.first || event }
        return if publish_events.blank?

        Indexing::Builders::PublisherNameBuilder.build(publish_events)
      end

      def stemmable_topics
        Indexing::Builders::TopicBuilder.build(Array(cocina.description.subject), filter: 'topic')
      end

      def publication_event
        @publication_event ||= Indexing::Selectors::EventSelector.select(events, 'publication')
      end

      def creation_event
        @creation_event ||= Indexing::Selectors::EventSelector.select(events, 'creation')
      end

      def events
        @events ||= Array(cocina.description.event).compact
      end

      def flat_event(event)
        event.parallelEvent.presence || Array(event)
      end

      def flat_value(value)
        value.parallelValue.presence || value.groupedValue.presence || value.structuredValue.presence || Array(value)
      end

      def all_search_text
        @all_search_text ||= Indexing::Builders::AllSearchTextBuilder.build(cocina.description)
      end

      def catalog_links
        return [] if cocina.is_a?(Cocina::Models::AdminPolicyWithMetadata)

        cocina.identification.catalogLinks
      end
    end
    # rubocop:enable Metrics/ClassLength
  end
end
