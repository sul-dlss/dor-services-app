# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
module Catalog
  # Creates a stub MARC 856 field (currently for transferring to symphony only) given a cocina object.
  class Marc856Generator
    # objects goverened by these APOs (ETD and EEMs) will get indicator 2 = 0, else 1
    BORN_DIGITAL_APOS = %w[druid:bx911tp9024 druid:jj305hm5259].freeze

    def self.create(cocina_object, thumbnail_service:)
      new(cocina_object, thumbnail_service:).create
    end

    def initialize(cocina_object, thumbnail_service:)
      @cocina_object = cocina_object
      @druid_id = cocina_object.externalIdentifier.delete_prefix('druid:')
      @access = cocina_object.access if cocina_object.respond_to?(:access)
      @thumbnail_service = thumbnail_service
    end

    # @return [Hash] all data required to create stub 856 records for this object
    def create
      return {} if ckeys.empty? && previous_ckeys.empty?

      # first create "blank" records for any previous catkeys
      record = {
        previous_ckeys: previous_ckeys.map { |previous_catkey| new_identifier_record(previous_catkey) }
      }

      unless ckeys.empty?
        catalog_record_id = ckeys.first
        record.merge!(released_to_searchworks?(@cocina_object) ? new_856_data(catalog_record_id) : new_identifier_record(catalog_record_id))
      end

      record
    end

    private

    # NOTE: this is the data to serialize a stub 856 record which is used to communicate with symphony (not a properly formatted 856 field nor a marc record)
    def new_856_data(ckey)
      {
        identifiers: new_identifier_record(ckey),
        indicator: born_digital?, ## true => 40, false => 41
        purl: "#{Settings.release.purl_base_url}/#{@druid_id}",
        object_type: get_object_type_from_uri,
        barcode:,
        thumb:,
        permissions: get_permissions_info,
        collections: get_collection_info,
        part: get_part_info,
        rights: get_rights_info
      }
    end

    def new_identifier_record(ckey)
      {
        ckey:,
        druid: @druid_id
      }
    end

    # This should only be reached for dro and collection objects
    def get_object_type_from_uri
      return 'item' if @cocina_object.dro?
      return 'collection' if @cocina_object.collection?

      nil
    end

    def get_permissions_info
      return '' unless @access.view == 'stanford' || (@access.respond_to?(:location) && @access.location)

      'Available to Stanford-affiliated users.'
    end

    def barcode
      @cocina_object.identification.barcode if @cocina_object.identification.respond_to?(:barcode)
    end

    # returns the collection information subfields if exists
    # @return [String] the collection information druid-value:catkey-value:title format
    # def get_x2_collection_info
    def get_collection_info
      return unless @cocina_object.respond_to?(:structural) && @cocina_object.structural

      collections = @cocina_object.structural.isMemberOf
      collection_info = []

      collections.each do |collection_druid|
        collection = CocinaObjectStore.find(collection_druid)
        next unless released_to_searchworks?(collection)

        catkey = collection.identification&.catalogLinks&.find { |link| link.catalog == 'symphony' }
        collection_info << {
          druid: collection.externalIdentifier.sub('druid:', ''),
          ckey: catkey&.catalogRecordId,
          label: Cocina::Models::Builders::TitleBuilder.build(collection.description.title)
        }
      end

      collection_info
    end

    def get_part_info
      {}.tap do |part|
        part[:label] = part_label if part_label.present?
        part[:sort] = part_sort if part_sort.present?
      end
    end

    def get_rights_info
      return get_collection_rights_info unless @access.respond_to?(:download)

      values = []

      values << 'dark' if @access.view == 'dark'

      if @access.view == 'world'
        values << 'world' if @access.download == 'world'
        values << 'citation' if @access.download == 'none'
      end
      values << 'cdl' if @access.controlledDigitalLending
      values << 'group=stanford' if @access.view == 'stanford' && @access.download == 'stanford'
      values << "location=#{@access.location}" if @access.location

      values
    end

    def get_collection_rights_info
      [@access.view]
    end

    def born_digital?
      BORN_DIGITAL_APOS.include? @cocina_object.administrative.hasAdminPolicy
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

    def ckeys
      @ckeys ||= fetch_ckeys(current: true)
    end

    def previous_ckeys
      @previous_ckeys ||= fetch_ckeys(current: false)
    end

    # List of current or previous ckeys for the cocina object (depending on parameter passed)
    # @param current [boolean] if you want the current or previous ckeys
    # @return [Array] previous or current catkeys for the object in an array, empty array if none exist
    def fetch_ckeys(current:)
      return [] unless @cocina_object.respond_to?(:identification) && @cocina_object.identification

      ckey_type = current ? 'symphony' : 'previous symphony'
      @cocina_object.identification.catalogLinks.select { |link| link.catalog == ckey_type }.map(&:catalogRecordId)
    end

    # the @id attribute of resource/file elements including extension
    # @return [String] thumbnail filename (nil if none found)
    def thumb
      @thumb ||= ERB::Util.url_encode(@thumbnail_service.thumb).presence
    end

    def part_types
      ['part name', 'part number']
    end

    def part_label
      @part_label ||= begin
        title_info = @cocina_object.description.title.first
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
      @part_sort ||= @cocina_object.description.note.find { |note| note.type == 'date/sequential designation' }&.value
    end
  end
end
# rubocop:enable Metrics/ClassLength
