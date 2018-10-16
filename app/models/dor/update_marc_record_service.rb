require 'open3'

module Dor
  class UpdateMarcRecordService < ServiceItem
    # objects goverened by these APOs (ETD and EEMs) will get indicator 2 = 0, else 1
    BORN_DIGITAL_APOS = %w(druid:bx911tp9024 druid:jj305hm5259).freeze

    def update
      push_symphony_records if ckeys?
    end

    def ckeys?
      (ckey.present? || previous_ckeys.present?)
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
    def generate_symphony_records
      return [] unless ckeys?

      # first create "blank" records for any previous catkeys
      records = previous_ckeys.map { |previous_catkey| get_identifier(previous_catkey) }

      # now add the current ckey
      if ckey.present?
        records << (released_to_searchworks? ? new_856_record(ckey) : get_identifier(ckey)) # if released to searchworks, create the record
      end

      records
    end

    def write_symphony_records(symphony_records)
      return if symphony_records.blank?
      symphony_file_name = "#{Dor::Config.release.symphony_path}/sdr-purl-856s"
      symphony_records.each do |symphony_record|
        command = "#{Dor::Config.release.write_marc_script} #{Shellwords.escape(symphony_record)} #{Shellwords.escape(symphony_file_name)}"
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
      new856 = "#{get_identifier(ckey)}#{get_856_cons} #{get_1st_indicator}#{get_2nd_indicator}#{get_z_field}#{get_u_field}#{get_x1_sdrpurl_marker}#{object_type.prepend('|x')}"
      new856 << barcode.prepend('|xbarcode:') unless barcode.nil?
      new856 << thumb.prepend('|xfile:') unless thumb.nil?
      new856 << get_x2_collection_info unless get_x2_collection_info.nil?
      new856 << get_x2_constituent_info unless get_x2_constituent_info.nil?
      new856 << get_x2_part_info unless get_x2_part_info.nil?
      new856
    end

    def get_identifier(ckey)
      "#{ckey}\t#{@druid_id}\t"
    end

    # It returns 856 constants
    def get_856_cons
      '.856.'
    end

    # It returns First Indicator for HTTP (4)
    def get_1st_indicator
      '4'
    end

    # It returns Second Indicator for Version of resource
    def get_2nd_indicator
      born_digital? ? '0' : '1'
    end

    # It returns text in the z field based on permissions
    def get_z_field
      # @dra_object.stanford_only_rights returns a 2 element list where presence of first element indicates stanford
      # only read restriction, and second element indicates the rule on the restriction, if any (e.g. 'no-download')
      if @dra_object.stanford_only_rights.first.present? || @dra_object.restricted_by_location?
        '|zAvailable to Stanford-affiliated users.'
      else
        ''
      end
    end

    # It builds the PURL uri based on the druid id
    def get_u_field
      "|u#{Dor::Config.release.purl_base_uri}/#{@druid_id}"
    end

    # It returns the SDR-PURL subfield
    def get_x1_sdrpurl_marker
      '|xSDR-PURL'
    end

    # It returns the collection information subfields if exists
    # @return [String] the collection information druid-value:catkey-value:title format
    def get_x2_collection_info
      collections = @druid_obj.collections
      coll_info = ''

      unless collections.empty?
        collections.each do |coll|
          coll_info << "|xcollection:#{coll.id.sub('druid:', '')}:#{Dor::ServiceItem.get_ckey(coll)}:#{coll.label}"
        end
      end

      coll_info
    end

    # It returns the constituent information subfields if exists
    # @return [String] the constituent information druid-value:catkey-value:title format
    def get_x2_constituent_info
      dor_items_for_constituents.map do |cons_obj|
        cons_obj_id = cons_obj.id.sub('druid:', '')
        cons_obj_title = cons_obj.datastreams['descMetadata'].ng_xml.xpath('//mods:mods/mods:titleInfo/mods:title', mods: 'http://www.loc.gov/mods/v3').first.content
        "|xset:#{cons_obj_id}:#{Dor::ServiceItem.get_ckey(cons_obj)}:#{cons_obj_title}"
      end.join('')
    end

    def get_x2_part_info
      title_info = primary_mods_title_info_element

      return unless title_info

      part_parts = title_info.children.select do |child|
        %w(partName partNumber).include?(child.name)
      end

      part_label = part_parts.map(&:text).compact.join(parts_delimiter(part_parts))

      part_sort = @druid_obj.datastreams['descMetadata'].ng_xml.xpath('//*[@type="date/sequential designation"]').first

      str = ''
      str << "|xlabel:#{part_label}" unless part_label.empty?
      str << "|xsort:#{part_sort.text}" if part_sort

      str
    end

    def born_digital?
      BORN_DIGITAL_APOS.include? @druid_obj.admin_policy_object_id
    end

    def released_to_searchworks?
      rel = @druid_obj.released_for.transform_keys { |key| key.to_s.upcase } # upcase all release tags to make the check case insensitive
      rel.blank? || rel['SEARCHWORKS'].blank? || rel['SEARCHWORKS']['release'].blank? ? false : rel['SEARCHWORKS']['release']
    end

    private

    def dor_items_for_constituents
      return [] unless @druid_obj.relationships(:is_constituent_of)
      @druid_obj.relationships(:is_constituent_of).map do |cons|
        cons_druid = cons.sub('info:fedora/', '')
        Dor::Item.find(cons_druid)
      end
    end

    def primary_mods_title_info_element
      return nil unless @druid_obj.datastreams['descMetadata']

      title_info = @druid_obj.datastreams['descMetadata'].ng_xml.xpath('//mods:mods/mods:titleInfo[not(@type)]', mods: 'http://www.loc.gov/mods/v3').first
      title_info ||= @druid_obj.datastreams['descMetadata'].ng_xml.xpath('//mods:mods/mods:titleInfo[@usage="primary"]', mods: 'http://www.loc.gov/mods/v3').first
      title_info ||= @druid_obj.datastreams['descMetadata'].ng_xml.xpath('//mods:mods/mods:titleInfo', mods: 'http://www.loc.gov/mods/v3').first

      title_info
    end

    # adapted from mods_display
    def parts_delimiter(elements)
      # index will retun nil which is not comparable so we call 100
      # if the element isn't present (thus meaning it's at the end of the list)
      if (elements.index { |c| c.name == 'partNumber' } || 100) < (elements.index { |c| c.name == 'partName' } || 100)
        ', '
      else
        '. '
      end
    end
  end
end
