require 'open3'

module Dor
  class UpdateMarcRecordService < ServiceItem
    def update
      push_symphony_record if ckey.present?
    end

    def push_symphony_record
      symphony_record = generate_symphony_record
      write_symphony_record symphony_record
    end

    # catkey: the catalog key that associates a DOR object with a specific Symphony record.
    # druid: the druid
    # .856. 41
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
    def generate_symphony_record
      return '' unless ckey.present?

      if released_to_searchworks
        purl_uri = get_u_field
        collection_info = get_x2_collection_info
        constituent_info = get_x2_constituent_info

        new856 = "#{ckey}\t#{@druid_id}\t#{get_856_cons} #{get_1st_indicator}#{get_2nd_indicator}#{get_z_field}#{purl_uri}#{get_x1_sdrpurl_marker}#{object_type.prepend('|x')}"
        new856 << barcode.prepend('|xbarcode:') unless barcode.nil?
        new856 << thumb.prepend('|xfile:') unless thumb.nil?
        new856 << collection_info unless collection_info.nil?
        new856 << constituent_info unless constituent_info.nil?
        new856
      else
        "#{ckey}\t#{@druid_id}\t"
      end
    end

    def write_symphony_record(symphony_record)
      return if symphony_record.nil? || symphony_record.empty?
      symphony_file_name = "#{Dor::Config.release.symphony_path}/sdr-purl-856s"
      command = "#{Dor::Config.release.write_marc_script} \'#{symphony_record}\' #{symphony_file_name}"
      run_write_script(command)
    end

    def run_write_script(command)
      Open3.popen3(command) do |_stdin, stdout, stderr, _wait_thr|
        stdout_text = stdout.read
        stderr_text = stderr.read

        if stdout_text.length > 0 || stderr_text.length > 0
          raise "Error in writing marc_record file using the command #{command}\n#{stdout_text}\n#{stderr_text}"
        end
      end
    end

    # It returns 856 constants
    def get_856_cons
      '.856.'
    end

    # It returns First Indicator for HTTP (4)
    def get_1st_indicator
      '4'
    end

    # It returns Second Indicator for Version of resource (1)
    def get_2nd_indicator
      '1'
    end

    # It returns text in the z field based on permissions
    def get_z_field
      if @dra_object.stanford_only_unrestricted? || @dra_object.stanford_only_downloadable?
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
        cons_obj_title = cons_obj.datastreams['descMetadata'].ng_xml.xpath('//mods/titleInfo/title').first.content
        "|xset:#{cons_obj_id}:#{Dor::ServiceItem.get_ckey(cons_obj)}:#{cons_obj_title}"
      end.join('')
    end

    def released_to_searchworks
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
  end
end
