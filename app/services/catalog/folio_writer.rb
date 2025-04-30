# frozen_string_literal: true

module Catalog
  # Updates the FOLIO MARC record's 856 fields
  class FolioWriter
    MAX_TRIES = Settings.catalog.folio.max_lookup_tries

    def self.save(cocina_object:, marc_856_data:)
      new(cocina_object:, marc_856_data:).save
    end

    def initialize(cocina_object:, marc_856_data:)
      @cocina_object = cocina_object
      @marc_856_data = marc_856_data
    end

    # Determines which Folio records to update and handles adding / deleting 856 fields
    # @raise [FolioClient::Error] FolioClient base error if problem interacting with Folio
    def save
      return if catalog_record_ids.empty? && previous_catalog_record_ids.empty?

      Honeybadger.context(
        druid: cocina_object.externalIdentifier,
        catalog_record_ids:,
        previous_catalog_record_ids:
      )

      # remove 856 for previous catkeys
      previous_catalog_record_ids.each do |previous_id|
        delete_previous_ids(catalog_record_id: previous_id, ignore_not_found: true)
      end

      # replace 856 for current catkeys
      catalog_record_ids.each { |catalog_record_id| update_current_ids(catalog_record_id:) }
    end

    private

    attr_reader :marc_856_data, :cocina_object

    def delete_previous_ids(catalog_record_id:, ignore_not_found: false)
      response = FolioClient.edit_marc_json(hrid: catalog_record_id) do |marc_json|
        marc_json['fields'].reject! { |field| (field['tag'] == '856') && field['content'].include?(purl_no_protocol) }
      end

      validate_quickmarc_response!(response)

      retry_lookup do
        # check that update has completed in FOLIO
        if instance_has_purl?(catalog_record_id:)
          raise StandardError,
                'PURL still found in instance record after update.'
        end
      end
    rescue FolioClient::ResourceNotFound
      raise unless ignore_not_found

      # if the previous record is not found in FOLIO, we can ignore it
      Rails.logger.warn "Previous folio instance id #{catalog_record_id} not found in FOLIO. Skipping."
    end

    def update_current_ids(catalog_record_id:) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
      response = FolioClient.edit_marc_json(hrid: catalog_record_id) do |marc_json|
        marc_json['fields'].reject! { |field| (field['tag'] == '856') && field['content'].include?(purl_no_protocol) }
        marc_json['fields'] << marc_856_field if ReleaseTagService.released_to_searchworks?(cocina_object:)
      end

      validate_quickmarc_response!(response)

      retry_lookup do
        if ReleaseTagService.released_to_searchworks?(cocina_object:)
          unless instance_has_purl?(catalog_record_id:)
            raise StandardError,
                  'No matching PURL found in instance record after update.'
          end

          unless updated?(catalog_record_id:)
            raise StandardError,
                  'No completely matching 856 found in source record after update.'
          end
        elsif instance_has_purl?(catalog_record_id:) # not released_to_searchworks
          # when unreleasing, checking instance record is sufficient for determining update completed
          raise StandardError, 'PURL still found in instance record after update.'
        end
      end
    end

    # @param [Hash,NilClass] response quickmarc response e.g.,
    #   {"message"=>"Record is too long to be a valid MARC binary record, it's length would be 100106 which is
    #   more than 99999 bytes", "type"=>"-4", "code"=>"INTERNAL_SERVER_ERROR"}
    def validate_quickmarc_response!(response)
      return if response.nil?

      Honeybadger.context(quickmarc_response: response)

      raise response['message']
    end

    def retry_lookup
      @try_count ||= 0
      yield
    rescue StandardError => e
      @try_count += 1
      Rails.logger.warn "Retrying Folio client operation for #{cocina_object.externalIdentifier} (#{@try_count} tries)"

      if @try_count <= MAX_TRIES
        sleep Settings.catalog.folio.sleep_seconds
        retry
      end

      Honeybadger.context(try_count: @try_count)

      raise e
    end

    # allow match with older catalog records' 856 fields with purls starting with http://
    def purl_no_protocol
      uri = URI.parse(cocina_object.description.purl)
      uri.host + uri.path
    end

    def catalog_record_ids
      @catalog_record_ids ||= fetch_catalog_record_ids(current: true)
    end

    def previous_catalog_record_ids
      @previous_catalog_record_ids ||= fetch_catalog_record_ids(current: false)
    end

    # List of current or previous catalog record ids for the cocina object (depending on parameter passed)
    # @param current [boolean] if you want the current or previous catalog record ids
    # @return [Array] previous or current catalog_record_ids for the object in an array, empty array if none exist
    def fetch_catalog_record_ids(current:)
      catalog_record_id_type = current ? 'folio' : 'previous folio'
      @cocina_object.identification.catalogLinks.filter_map do |link|
        link.catalogRecordId if link.catalog == catalog_record_id_type
      end
    end

    def marc_856_field
      field = { tag: '856', isProtected: false }
      content = marc_856_data[:subfields].filter_map do |subfield|
        "$#{subfield[:code]} #{subfield[:value]}" unless subfield[:value].nil?
      end
      field[:indicators] = marc_856_data[:indicators].chars
      field[:content] = content.join(' ')
      field.stringify_keys
    end

    # check whether PURL is in FOLIO instance record
    def instance_has_purl?(catalog_record_id:)
      instance = FolioClient.fetch_instance_info(hrid: catalog_record_id)
      purls = instance['electronicAccess'].select { |field| field['uri'] == cocina_object.description.purl }
      purls.present?
    end

    # transform marc_856_data to source record format which has a different JSON format than what was initially sent
    # in edit_marc_json
    def source_856_field # rubocop:disable Metrics/AbcSize
      content = {}
      content[:ind1] = marc_856_data[:indicators][0]
      content[:ind2] = marc_856_data[:indicators][1]
      content[:subfields] = marc_856_data[:subfields].filter_map do |subfield|
        { subfield[:code] => subfield[:value] } unless subfield[:value].nil?
      end
      full_field = { 856 => content }
      full_field.deep_stringify_keys
    end

    # compare transformed 856 data sent to FOLIO with the 856 currently on the FOLIO record
    def updated?(catalog_record_id:)
      current = current_folio856(catalog_record_id:)
      intended = source_856_field
      subfields_match?(intended, current) && indicators_match?(intended, current)
    end

    # get the matching 856 on the current source record in FOLIO
    def current_folio856(catalog_record_id:) # rubocop:disable Metrics/AbcSize
      source_record = FolioClient.fetch_marc_hash(instance_hrid: catalog_record_id)
      source_record_856s = source_record['fields'].select { |tag| tag.key?('856') }
      raise StandardError, 'No 856 in source record.' unless source_record_856s

      matching_fields = source_record_856s.select do |field|
        field['856']['subfields'].any? do |subfield|
          subfield['u'] == cocina_object.description.purl
        end
      end
      return matching_fields.first unless matching_fields.size > 1

      raise StandardError, 'More than one matching field with a PURL found on FOLIO record.'
    end

    def subfields_match?(intended, current)
      intended['856']['subfields'].to_set == current['856']['subfields'].to_set
    end

    def indicators_match?(intended, current)
      intended['856']['ind1'] == current['856']['ind1'] && intended['856']['ind2'] == current['856']['ind2']
    end
  end
end
