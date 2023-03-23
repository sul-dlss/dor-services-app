# frozen_string_literal: true

module Catalog
  # Updates the FOLIO MARC record's 856 fields
  class FolioWriter
    MAX_TRIES = 3

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

      # remove 856 for previous catkeys
      previous_catalog_record_ids.each { |previous_id| delete_previous_ids(catalog_record_id: previous_id) }

      # replace 856 for current catkeys
      catalog_record_ids.each { |catalog_record_id| update_current_ids(catalog_record_id:) }
    end

    private

    attr_reader :marc_856_data, :cocina_object

    def delete_previous_ids(catalog_record_id:)
      retry_connection do
        FolioClient.edit_marc_json(hrid: catalog_record_id) do |marc_json|
          marc_json['fields'].reject! { |field| (field['tag'] == '856') && (field['content'].include? purl_subfield) }
        end
      end
    end

    def update_current_ids(catalog_record_id:)
      retry_connection do
        FolioClient.edit_marc_json(hrid: catalog_record_id) do |marc_json|
          marc_json['fields'].reject! { |field| (field['tag'] == '856') && (field['content'].include? purl_subfield) }
          marc_json['fields'] << marc_856_field if ReleaseTags.released_to_searchworks?(cocina_object:)
        end
      end
    end

    def retry_connection
      @try_count ||= 0
      yield
    rescue StandardError => e
      @try_count += 1
      Rails.logger.warn "Retrying Folio client operation for #{cocina_object.externalIdentifier} (#{@try_count} tries)"
      retry if @try_count <= MAX_TRIES

      Honeybadger.notify(
        'Error retrying Folio edit operations',
        error_message: e.message,
        error_class: e.class,
        backtrace: e.backtrace,
        context: {
          druid: cocina_object.externalIdentifier,
          try_count: @try_count
        }
      )
    end

    def purl_subfield
      "$u #{cocina_object.description.purl}"
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
      @cocina_object.identification.catalogLinks.filter_map { |link| link.catalogRecordId if link.catalog == catalog_record_id_type }
    end

    def marc_856_field
      field = { tag: '856', isProtected: false }
      content = marc_856_data[:subfields].filter_map { |subfield| "$#{subfield[:code]} #{subfield[:value]}" unless subfield[:value].nil? }
      field[:indicators] = marc_856_data[:indicators].chars
      field[:content] = content.join(' ')
      field.stringify_keys
    end
  end
end
