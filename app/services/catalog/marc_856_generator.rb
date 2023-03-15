# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
module Catalog
  # Creates a hash of identifiers and MARC 856 field data given a cocina object.
  class Marc856Generator
    # objects goverened by these APOs (ETD and EEMs) will get indicator 2 = 0, else 1
    BORN_DIGITAL_APOS = %w[druid:bx911tp9024 druid:jj305hm5259].freeze

    def self.create(cocina_object, thumbnail_service:, catalog: 'folio')
      new(cocina_object, thumbnail_service:, catalog:).create
    end

    # @param [Cocina::Models::DRO,Cocina::Models::Collection,Cocina::Models::AdminPolicy] cocina_object
    # @param [ThumbnailService] thumbnail_service
    # @param [String] catalog used to determine the catalog record id to use for the collection
    def initialize(cocina_object, thumbnail_service:, catalog: 'folio')
      @cocina_object = cocina_object
      @thumbnail_service = thumbnail_service
      @catalog = catalog
    end

    # @return [Hash] of data required to update 856 fields for purls pertaining to this object
    # indicators: 40 or 41 (depending on APO)
    # subfields: (ordered)
    # u - access:
    # z - purl: the full Purl URL
    # x - sdr_purl_marker (required): The string SDR-PURL as a marker to identify 856 entries managed through DOR
    # x - object_type (required): Object type (<identityMetadata><objectType>) - item, collection,
    #                         (future types of sets to describe other aggregations like albums, atlases, etc)
    # x - barcode (optional): the barcode if known (<identityMetadata><otherId name="barcode">, recorded as barcode:barcode-value
    # x - thumbnail (optional): the file-id to be used as thumb if available, recorded as file:file-id-value
    # x - collections (optional): Collection(s) this object is a member of, formatted as: druid:catalog_record_id:label
    # x - parts-label (optional):
    # x - parts-sort (optional):
    # x- rights (optional): High-level rights summary
    def create
      # NOTE: this is the data to go in an 856 field (not a properly formatted 856 field nor a marc record)
      {
        indicators:,
        subfields: [
          subfield_z_access,
          subfield_u_purl,
          subfield_x_sdr_purl_marker,
          subfield_x_object_type,
          subfield_x_barcode,
          subfield_x_thumbnail,
          subfield_x_collections,
          subfield_x_parts,
          subfield_x_rights
        ].compact.flatten
      }
    end

    private

    attr_reader :catalog, :thumbnail_service, :cocina_object

    def bare_druid
      @bare_druid ||= cocina_object.externalIdentifier.delete_prefix('druid:')
    end

    def access
      @access ||= cocina_object.access if cocina_object.respond_to?(:access)
    end

    def indicators
      "#{first_indicator}#{second_indicator}"
    end

    def first_indicator
      '4'
    end

    def second_indicator
      born_digital? ? '0' : '1'
    end

    def born_digital?
      BORN_DIGITAL_APOS.include? cocina_object.administrative.hasAdminPolicy
    end

    def subfield_z_access
      return unless access.view == 'stanford' || (access.respond_to?(:location) && access.location)

      { code: 'z', value: 'Available to Stanford-affiliated users.' }
    end

    def subfield_u_purl
      { code: 'u', value: "#{Settings.release.purl_base_url}/#{bare_druid}" }
    end

    # returns the SDR-PURL subfield
    def subfield_x_sdr_purl_marker
      { code: 'x', value: 'SDR-PURL' }
    end

    # This should only be reached for dro and collection objects
    def subfield_x_object_type
      return { code: 'x', value: 'item' } if cocina_object.dro?
      return { code: 'x', value: 'collection' } if cocina_object.collection?
    end

    def subfield_x_barcode
      return unless cocina_object.identification.respond_to?(:barcode) && cocina_object.identification.barcode

      { code: 'x', value: "barcode:#{cocina_object.identification.barcode}" }
    end

    # the @id attribute of resource/file elements including extension
    # @return [String] thumbnail filename (nil if none found)
    def subfield_x_thumbnail
      return unless thumbnail_service.thumb

      { code: 'x', value: "file:#{ERB::Util.url_encode(thumbnail_service.thumb)}" }
    end

    # returns the collection information subfields if exists
    # @return [String] the collection information druid-value:catalog-record-id-value:title format
    def subfield_x_collections
      return unless cocina_object.respond_to?(:structural) && cocina_object.structural

      collections = cocina_object.structural.isMemberOf
      collection_info = []

      collections.each do |collection_druid|
        collection = CocinaObjectStore.find(collection_druid)
        next unless released_to_searchworks?(collection)

        catalog_link = collection.identification&.catalogLinks&.find { |link| link.catalog == catalog }
        collection_info << { code: 'x', value: "collection:#{collection.externalIdentifier.sub('druid:', '')}:#{catalog_link&.catalogRecordId}:#{Cocina::Models::Builders::TitleBuilder.build(collection.description.title)}" }
      end

      collection_info
    end

    def subfield_x_parts
      return unless part_label.present? || part_sort.present?

      [].tap do |part|
        part << { code: 'x', value: "label:#{part_label}" } if part_label.present?
        part << { code: 'x', value: "sort:#{part_sort}" } if part_sort.present?
      end
    end

    def subfield_x_rights
      return [{ code: 'x', value: "rights:#{access.view}" }] unless access.respond_to?(:download)

      values = []

      values << 'rights:dark' if access.view == 'dark'

      if access.view == 'world'
        values << 'rights:world' if access.download == 'world'
        values << 'rights:citation' if access.download == 'none'
      end
      values << 'rights:cdl' if access.controlledDigitalLending
      values << 'rights:group=stanford' if access.view == 'stanford' && access.download == 'stanford'
      values << "rights:location=#{access.location}" if access.location

      values.map { |right| { code: 'x', value: right } }
    end

    def released_to_searchworks?(cocina_object)
      released_for = ::ReleaseTags.for(cocina_object:)
      rel = released_for.transform_keys { |key| key.to_s.upcase }
      rel.dig('SEARCHWORKS', 'release').presence || false
    end

    # adapted from mods_display
    def parts_delimiter(elements)
      # index will retun nil which is not comparable so we call 100
      # if the element isn't present (thus meaning it's at the end of the list)
      if (elements.index { |c| c.type == 'part number' } || 100) < (elements.index { |c| c.type == 'part name' } || 100)
        ', '
      else
        '. '
      end
    end

    def part_types
      ['part name', 'part number']
    end

    def part_label
      @part_label ||= begin
        title_info = cocina_object.description.title.first
        # Need to check both structuredValue on title_info and in parallelValues
        structured_values = []
        structured_values << title_info.structuredValue if title_info.structuredValue.present?
        title_info.parallelValue.each { |parallel_value| structured_values << parallel_value.structuredValue if parallel_value.structuredValue.present? }

        part_parts = []
        structured_values.each do |structured_value|
          structured_value.each do |part|
            part_parts << part if part_types.include? part.type
          end
        end

        part_parts.filter_map(&:value).join(parts_delimiter(part_parts))
      end
    end

    def part_sort
      @part_sort ||= cocina_object.description.note.find { |note| note.type == 'date/sequential designation' }&.value
    end
  end
end
# rubocop:enable Metrics/ClassLength
