# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
module Catalog
  # Creates records that start with (ils id)\t(druid)\t and then have
  # 0 or 1 (makings of MARC 856 fields), given a cocina object, ultimately to be leveraged by SearchWorks.
  # There is a script on the Symphony side that expects records in exactly the String format here in order to
  #   munge the 856 information into the appropriate Symphony records.
  # We think of these as "stub" records, because they are not complete or correct MARC records.
  # If no 856 field follows, the ILS is meant to remove any existing 856 field with a purl
  # If a 856 field follows, the ILS is meant to add it or to replace the existing 856 field with a purl
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

    # @return [Array] all stub 856 records for this object (a stub record is not valid MARC, but may contain
    #   the makings of a valid MARC 856 field) There is a script on the Symphony side that expects records in
    #   exactly the String format here in order to munge the 856 information into the appropriate Symphony MARC records.
    # catkey: the catalog key that associates a DOR object with a specific Symphony record.
    # druid: the druid
    # .856. 41 or 40 (depending on APO)
    # subfield u (required): the full Purl URL
    # subfield x #1 (required): The string SDR-PURL as a marker to identify 856 entries managed through DOR
    # subfield x #2 (required): Object type (<identityMetadata><objectType>) - item, collection,
    #     (future types of sets to describe other aggregations like albums, atlases, etc)
    # subfield x #3 (required): The display type of the object.
    #     use an explicit display type from the object if present (<identityMetadata><displayType>)
    #     else use the value of the <contentMetadata> "type" attribute if present, e.g., image, book, file
    #     else use the value "citation"
    # subfield x #4 (optional): the barcode if known (<identityMetadata><otherId name="barcode">, recorded as barcode:barcode-value
    # subfield x #5 (optional): the file-id to be used as thumb if available, recorded as file:file-id-value
    # subfield x #6..n (optional): Collection(s) this object is a member of, recorded as collection:druid-value:ckey-value:title
    # subfield x #7..n (optional): label and part sort keys for the member
    # subfield x #8..n (optional): High-level rights summary
    def create
      return [] if ckeys.empty? && previous_ckeys.empty?

      # first create "blank" records for any previous catkeys
      records = previous_ckeys.map { |previous_catkey| new_identifier_record(previous_catkey) }

      # now add the current ckey
      unless ckeys.empty?
        catalog_record_id = ckeys.first
        records << (released_to_searchworks?(@cocina_object) ? new_856_record(catalog_record_id) : new_identifier_record(catalog_record_id))
      end

      records
    end

    private

    # NOTE: this is a stub record which is not valid MARC, but contains a String version with data that could be munged into a valid MARC 856 field)
    def new_856_record(ckey)
      new856 = "#{new_identifier_record(ckey)}#{tag856} #{first_indicator}#{second_indicator}#{z_subfield}#{u_subfield}#{x_subfield_sdrpurl}|x#{get_object_type_from_uri}"
      new856 += "|xbarcode:#{@cocina_object.identification.barcode}" if @cocina_object.identification.respond_to?(:barcode) && @cocina_object.identification.barcode
      new856 += "|xfile:#{thumb}" unless thumb.nil?
      new856 += x_subfields_for_collections unless x_subfields_for_collections.nil?
      new856 += x_subfields_part_info unless x_subfields_part_info.nil?
      new856 += x_subfields_rights_info unless x_subfields_rights_info.nil?
      new856
    end

    # the catkey and druid, each followed by a tab, as Symphony script expects these stub records to start with
    def new_identifier_record(ckey)
      "#{ckey}\t#{@druid_id}\t"
    end

    # This should only be reached for dro and collection objects
    def get_object_type_from_uri
      return 'item' if @cocina_object.dro?
      return 'collection' if @cocina_object.collection?

      nil
    end

    # returns MARC 856 tag in format Symphony script expects
    def tag856
      '.856.'
    end

    # returns MARC 856 First Indicator set as HTTP (4)
    def first_indicator
      '4'
    end

    # returns MARC 856 Second Indicator set as Version of resource
    def second_indicator
      born_digital? ? '0' : '1'
    end

    # @return [String] |z followed by permissions, in format Symphony script expects
    def z_subfield
      return '' unless @access.view == 'stanford' || (@access.respond_to?(:location) && @access.location)

      '|zAvailable to Stanford-affiliated users.'
    end

    # @return [String] |u followed by PURL uri, in format Symphony script expects
    def u_subfield
      "|u#{Settings.release.purl_base_url}/#{@druid_id}"
    end

    # @return [String] |x with SDR-PURL, in format Symphony script expects
    def x_subfield_sdrpurl
      '|xSDR-PURL'
    end

    # returns the collection information x subfields in format Symphony script expects, if coll info exists
    # @return [String] |x followed by the collection information in druid:catkey:title format, in format Symphony script expects
    def x_subfields_for_collections
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

    # @return [String] zero, one or more |x with part label or sort, in format Symphony script expects
    def x_subfields_part_info
      str = ''
      str += "|xlabel:#{part_label}" if part_label.present?
      str += "|xsort:#{part_sort}" if part_sort.present?
      str
    end

    # @return [String] zero, one or more |x with rights info from cocina, in format Symphony script expects
    def x_subfields_rights_info
      return x_subfields_collection_rights_info unless @access.respond_to?(:download)

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

    # @return [String] |x with collection rights info from cocina, in format Symphony script expects
    def x_subfields_collection_rights_info
      "|xrights:#{@access.view}"
    end

    def born_digital?
      BORN_DIGITAL_APOS.include? @cocina_object.administrative.hasAdminPolicy
    end

    def released_to_searchworks?(cocina_object)
      released_for = ::ReleaseTags.for(cocina_object:)
      rel = released_for.transform_keys { |key| key.to_s.upcase } # upcase all release tags to make the check case insensitive
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
