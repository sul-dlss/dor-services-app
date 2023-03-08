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
    # catkey: the catalog key that associates a DOR object with a specific Symphony record.
    # druid: the druid
    # .856. 41 or 40 (depending on APO)
    # Subfield u (required): the full Purl URL
    # Subfield x #1 (required): The string SDR-PURL as a marker to identify 856 entries managed through DOR
    # Subfield x #2 (required): Object type (<identityMetadata><objectType>) - item, collection,
    #     (future types of sets to describe other aggregations like albums, atlases, etc)
    # Subfield x #3 (required): The display type of the object.
    #     use an explicit display type from the object if present (<identityMetadata><displayType>)
    #     else use the value of the <contentMetadata> "type" attribute if present, e.g., image, book, file
    #     else use the value "citation"
    # Subfield x #4 (optional): the barcode if known (<identityMetadata><otherId name="barcode">, recorded as barcode:barcode-value
    # Subfield x #5 (optional): the file-id to be used as thumb if available, recorded as file:file-id-value
    # Subfield x #6..n (optional): Collection(s) this object is a member of, recorded as collection:druid-value:ckey-value:title
    # Subfield x #7..n (optional): label and part sort keys for the member
    # Subfield x #8..n (optional): High-level rights summary
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
        identifier: new_identifier_record(ckey),
        indicators: [first_indicator, second_indicator].join,
        subfield_z:,
        subfield_u:,
        subfield_x1:,
        subfield_x2:,
        subfield_x4:,
        subfield_x5:,
        subfield_x6:,
        subfield_x7:,
        subfield_x8:
      }
    end

    def new_identifier_record(ckey)
      "#{ckey}\t#{@druid_id}\t"
    end

    # This should only be reached for dro and collection objects
    def subfield_x2
      return '|xitem' if @cocina_object.dro?
      return '|xcollection' if @cocina_object.collection?

      nil
    end

    # returns the SDR-PURL subfield
    def subfield_x1
      '|xSDR-PURL'
    end

    def subfield_z
      return '' unless @access.view == 'stanford' || (@access.respond_to?(:location) && @access.location)

      '|zAvailable to Stanford-affiliated users.'
    end

    def subfield_u
      "|u#{Settings.release.purl_base_url}/#{@druid_id}"
    end

    def subfield_x4
      return unless @cocina_object.identification.respond_to?(:barcode) && @cocina_object.identification.barcode

      "|xbarcode:#{@cocina_object.identification.barcode}"
    end

    # returns the collection information subfields if exists
    # @return [String] the collection information druid-value:catkey-value:title format
    # def get_x2_collection_info
    def subfield_x6
      return unless @cocina_object.respond_to?(:structural) && @cocina_object.structural

      collections = @cocina_object.structural.isMemberOf
      collection_info = ''

      collections.each do |collection_druid|
        collection = CocinaObjectStore.find(collection_druid)
        next unless released_to_searchworks?(collection)

        catkey = collection.identification&.catalogLinks&.find { |link| link.catalog == 'symphony' }
        collection_info += "|xcollection:#{collection.externalIdentifier.sub('druid:',
                                                                             '')}:#{catkey&.catalogRecordId}:#{Cocina::Models::Builders::TitleBuilder.build(collection.description.title)}"
      end

      collection_info
    end

    def subfield_x7
      str = ''
      str += "|xlabel:#{part_label}" if part_label.present?
      str += "|xsort:#{part_sort}" if part_sort.present?
      str
    end

    def subfield_x8
      return get_collection_rights_info unless @access.respond_to?(:download)

      values = []

      values << 'rights:dark' if @access.view == 'dark'

      if @access.view == 'world'
        values << 'rights:world' if @access.download == 'world'
        values << 'rights:citation' if @access.download == 'none'
      end
      values << 'rights:cdl' if @access.controlledDigitalLending
      values << 'rights:group=stanford' if @access.view == 'stanford' && @access.download == 'stanford'
      values << "rights:location=#{@access.location}" if @access.location

      values.map { |value| "|x#{value}" }.join
    end

    def get_collection_rights_info
      "|xrights:#{@access.view}"
    end

    def first_indicator
      '4'
    end

    def second_indicator
      born_digital? ? '0' : '1'
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
    def subfield_x5
      return unless @thumbnail_service.thumb

      "|xfile:#{ERB::Util.url_encode(@thumbnail_service.thumb)}"
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
