# frozen_string_literal: true

require 'open3'
require 'shellwords'

module Dor
  # rubocop:disable Metrics/ClassLength
  class UpdateMarcRecordService
    # objects goverened by these APOs (ETD and EEMs) will get indicator 2 = 0, else 1
    BORN_DIGITAL_APOS = %w(druid:bx911tp9024 druid:jj305hm5259).freeze

    def initialize(druid_obj, thumbnail_service:)
      @druid_obj = druid_obj
      @druid_id = Dor::PidUtils.remove_druid_prefix(druid_obj.externalIdentifier)
      @dra_object = druid_obj.access
      @thumbnail_service = thumbnail_service
    end

    def update
      push_symphony_records if ckeys?
    end

    def ckeys?
      @druid_obj.identification.catalogLinks.find {|link| link.catalog == 'symphony'}.present?
      # (@druid_obj.catkey.present? || previous_ckeys.present?)
      # TODO: Map previous_catkey
    end

    def push_symphony_records
      symphony_records = generate_symphony_records
      write_symphony_records symphony_records
    end

    # @return [Array] all 856 records for this object
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
    # Subfield x #7..n (optional): Set(s) this object is a member of, recorded as set:druid-value:ckey-value:title
    # Subfield x #8..n (optional): label and part sort keys for the member
    # Subfield x #9..n (optional): High-level rights summary
    def generate_symphony_records
      return [] unless ckeys?

      # first create "blank" records for any previous catkeys
      records = previous_ckeys.map { |previous_catkey| get_identifier(previous_catkey) }

      # now add the current ckey
      if @druid_obj.identification.catalogLinks.find {|link| link.catalog == 'symphony'}.present?
        records << (released_to_searchworks? ? new_856_record(@druid_obj.identification.catalogLinks.find {|link| link.catalog == 'symphony'}.catalogRecordId) : get_identifier(@druid_obj.identification.catalogLinks.find {|link| link.catalog == 'symphony'}.catalogRecordId)) # if released to searchworks, create the record
      end

      records
    end

    def write_symphony_records(symphony_records)
      return if symphony_records.blank?

      symphony_file_name = "#{Settings.release.symphony_path}/sdr-purl-856s"
      symphony_records.each do |symphony_record|
        command = "#{Settings.release.write_marc_script} #{Shellwords.escape(symphony_record)} #{Shellwords.escape(symphony_file_name)}"
        run_write_script(command)
      end
    end

    def run_write_script(command)
      Open3.popen3(command) do |_stdin, stdout, stderr, _wait_thr|
        stdout_text = stdout.read
        stderr_text = stderr.read
        raise "Error in writing marc_record file using the command #{command}\n#{stdout_text}\n#{stderr_text}" if stdout_text.length > 0 || stderr_text.length > 0
      end
    end

    def new_856_record(ckey)
      new856 = "#{get_identifier(ckey)}#{get_856_cons} #{get_1st_indicator}#{get_2nd_indicator}#{get_z_field}#{get_u_field}#{get_x1_sdrpurl_marker}|x#{@druid_obj.type}"
      new856 += "|xbarcode:#{@druid_obj.identification.barcode}" unless @druid_obj.identification.barcode.nil?
      new856 += "|xfile:#{thumb}" unless thumb.nil?
      new856 += get_x2_collection_info unless get_x2_collection_info.nil?
      new856 += get_x2_constituent_info unless get_x2_constituent_info.nil?
      new856 += get_x2_part_info unless get_x2_part_info.nil?
      new856 += get_x2_rights_info unless get_x2_rights_info.nil?
      new856
    end

    def get_identifier(ckey)
      "#{ckey}\t#{@druid_id}\t"
    end

    # returns 856 constants
    def get_856_cons
      '.856.'
    end

    # returns First Indicator for HTTP (4)
    def get_1st_indicator
      '4'
    end

    # returns Second Indicator for Version of resource
    def get_2nd_indicator
      born_digital? ? '0' : '1'
    end

    # returns text in the z field based on permissions
    def get_z_field
      # @dra_object.stanford_only_rights returns a 2 element list where presence of first element indicates stanford
      # only read restriction, and second element indicates the rule on the restriction, if any (e.g. 'no-download')
      if @dra_object.access == 'stanford' || @dra_object.readLocation.present?
        '|zAvailable to Stanford-affiliated users.'
      else
        ''
      end
    end

    # builds the PURL uri based on the druid id
    def get_u_field
      "|u#{Settings.release.purl_base_url}/#{@druid_id}"
    end

    # returns the SDR-PURL subfield
    def get_x1_sdrpurl_marker
      '|xSDR-PURL'
    end

    # returns the collection information subfields if exists
    # @return [String] the collection information druid-value:catkey-value:title format
    def get_x2_collection_info
      collections = @druid_obj.structural.isMemberOf
      collection_info = ''

      unless collections.empty?
        collections.each do |collection_druid|
          collection = CocinaObjectStore.find(collection_druid)
          catkey = collection.identification&.catalogLinks&.find { |link| link.catalog == 'symphony' }
          collection_info += "|xcollection:#{collection.externalIdentifier.sub('druid:', '')}:#{catkey&.catalogRecordId}:#{collection.label}"
        end
      end

      collection_info
    end

    # returns the constituent information subfields if exists
    # @return [String] the constituent information druid-value:catkey-value:title format
    def get_x2_constituent_info
      dor_items_for_constituents.map do |cons_obj|
        cons_obj_id = cons_obj.id.sub('druid:', '')
        cons_obj_title = cons_obj.datastreams['descMetadata'].ng_xml.xpath('//mods:mods/mods:titleInfo/mods:title', mods: 'http://www.loc.gov/mods/v3').first.content
        "|xset:#{cons_obj_id}:#{cons_obj.catkey}:#{cons_obj_title}"
      end.join
    end

    def get_x2_part_info
      title_info = @druid_obj.description&.title&.first
      return unless title_info.respond_to?(:structuredValue) && title_info.structuredValue

      part_parts = title_info.structuredValue.select { |part| ['part name', 'part number'].include? part.type }

      part_label = part_parts.filter_map(&:value).join(parts_delimiter(part_parts))

      part_sort = title_info.structuredValue.select { |part| 'date/sequential designation'.include? part.type }

      str = ''
      str += "|xlabel:#{part_label}" unless part_label.empty?
      str += "|xsort:#{part_sort.first.value}" unless part_sort.empty?

      str
    end

    def get_x2_rights_info
      values = []

      values << 'rights:dark' if @dra_object.access == 'dark'

      if @dra_object.access == 'world'
        values << 'rights:cdl' if @dra_object.download == 'stanford'
        values << 'rights:world' if @dra_object.download == 'world'
        values << 'rights:citation' if @dra_object.download == 'none'
      end

      values << 'rights:group=stanford' if @dra_object.access == 'stanford' && @dra_object.download == 'stanford'
      values << "rights:location=#{@dra_object.readLocation}" if @dra_object.readLocation

      values.map { |value| "|x#{value}" }.join
    end

    def born_digital?
      BORN_DIGITAL_APOS.include? @druid_obj.administrative.hasAdminPolicy
    end

    def released_to_searchworks?
      rel = released_for.transform_keys { |key| key.to_s.upcase } # upcase all release tags to make the check case insensitive
      rel.dig('SEARCHWORKS', 'release').presence || false
    end

    private

    def released_for
      ::ReleaseTags.for(item: @druid_obj)
    end

    def dor_items_for_constituents
      return [] unless @druid_obj.respond_to?(:structural) && @druid_obj.structural

      @druid_obj.structural.isMemberOf
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

    # the previous ckeys for the current object
    # @return [Array] previous catkeys for the object in an array, empty array if none exist
    def previous_ckeys
      # @druid_obj.previous_catkeys.reject(&:empty?)
      # TODO: Map previous_catkeys
      []
    end

    # the @id attribute of resource/file elements including extension
    # @return [String] thumbnail filename (nil if none found)
    def thumb
      @thumb ||= ERB::Util.url_encode(@thumbnail_service.thumb).presence
    end
  end
  # rubocop:enable Metrics/ClassLength
end
