# frozen_string_literal: true

module Indexing
  module Indexers
    # Indexes the descriptive metadata
    class DescriptiveMetadataIndexer
      attr_reader :cocina

      def initialize(cocina:, **)
        @cocina = cocina
      end

      METHODS = {
        # title
        'main_title_tenim' => :main_title, # for searching; 2 more field types are copyFields in solr schema.xml
        'full_title_tenim' => :full_title, # for searching; 1 more field type is copyField in solr schema.xml
        'additional_titles_tenim' => :additional_titles, # for searching; 1 more field type is copyField in
        # solr schema.xml
        'display_title_ss' => :display_title, # for display in Argo

        # contributor
        'author_text_nostem_im' => :author_primary, # primary author tokenized but not stemmed
        'author_display_ss' => :author_primary, # used for author display in Argo
        'contributor_text_nostem_im' => :author_all, # author names should be tokenized but not stemmed
        'contributor_orcids_ssimdv' => :orcids,

        # topic
        'subject_topic_other_ssimdv' => :subject_topics_other,
        'subject_topic_tesim' => :subject_topics,

        # publication
        'originInfo_date_created_tesim' => :creation_date,
        'originInfo_publisher_tesim' => :publisher_name,
        'originInfo_place_placeTerm_tesim' => :event_place, # do we want this?
        'publication_year_ssidv' => :pub_year_int,

        # SW facets plus a friend facet
        'sw_format_ssimdv' => :sw_format,
        'mods_typeOfResource_ssimdv' => :resource_type, # MODS Resource Type facet
        'genre_ssimdv' => :genres,
        'sw_language_names_ssimdv' => :searchworks_language_names,
        'subject_place_ssimdv' => :subject_places,

        # all the descriptive data that we want to search on, with different flavors for better recall and precision
        'descriptive_tiv' => :all_search_text, # ICU tokenized, ICU folded
        'descriptive_text_nostem_i' => :all_search_text, # whitespace tokenized, ICU folded, word delimited
        'descriptive_teiv' => :all_search_text # ICU tokenized, ICU folded, minimal stemming
      }.freeze

      # @return [Hash] the partial solr document for descriptive metadata
      def to_solr
        {}.tap do |doc|
          METHODS.each do |field, method|
            doc[field] = send(method)
          rescue StandardError => e
            Honeybadger.notify(e) # Notify HB, but finish indexing.
          end
        end.compact_blank
      end

      private

      delegate :subject_topics_other, :subject_topics, :pub_year_int, :genres, :searchworks_language_names,
               :subject_places, to: :cocina_display_record

      def sw_format
        Indexers::SearchworksFormatIndexer.value(cocina_display_record: cocina_display_record)
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
        @resource_type ||= cocina_display_record.mods_resource_types - ['collection', 'manuscript']
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

      def publication_event
        @publication_event ||= Indexing::Selectors::EventSelector.select(events, 'publication')
      end

      def creation_event
        @creation_event ||= Indexing::Selectors::EventSelector.select(events, 'creation')
      end

      def events
        @events ||= Array(cocina.description.event).compact
      end

      def all_search_text
        @all_search_text ||= Indexing::Builders::AllSearchTextBuilder.build(cocina.description)
      end

      def catalog_links
        return [] if cocina.is_a?(Cocina::Models::AdminPolicyWithMetadata)

        Array(cocina.identification.catalogLinks)
      end

      def cocina_display_record
        @cocina_display_record ||= CocinaDisplay::CocinaRecord.new(cocina.to_h.with_indifferent_access)
      end
    end
  end
end
