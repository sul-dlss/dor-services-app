# frozen_string_literal: true

# Invoke via:
# bin/rails r -e production "InvalidW3cdtfDates.report"
class InvalidW3cdtfDates
  # NOTE: Prefer strict JSON querying over lax when using the `.**` operator, per
  #       https://www.postgresql.org/docs/14/functions-json.html#STRICT-AND-LAX-MODES
  #
  # > The .** accessor can lead to surprising results when using the lax mode.
  # > ... This happens because the .** accessor selects both the segments array
  # > and each of its elements, while the .HR accessor automatically unwraps
  # > arrays when using the lax mode. To avoid surprising results, we recommend
  # > using the .** accessor only in the strict mode.

  # find cocina objects that have at least one date with the encoding
  DATE_JSONB_PATH = 'strict $.**.date ? (@.**.encoding.code == "w3cdtf")'
  # find individual cocina date objects that match the encoding
  DATE_ENCODING_JSON_PATH = JsonPath.new('$..encoding.code[?(@ == "w3cdtf")]').freeze
  # find all the values for a cocina date object (e.g. there may be a structuredValue)
  DATE_VALUE_JSON_PATH = JsonPath.new('$..value').freeze

  SQL = <<~SQL.squish.freeze
    SELECT jsonb_path_query_array(description, '#{DATE_JSONB_PATH}') ->> 0 as dates,
           external_identifier,
           jsonb_path_query(identification, '$.catalogLinks[*] ? (@.catalog == "folio").catalogRecordId') ->> 0 as catalogRecordId,
           jsonb_path_query(structural, '$.isMemberOf') ->> 0 as collection_id
           FROM "dros" WHERE
           jsonb_path_exists(description, '#{DATE_JSONB_PATH}')
  SQL

  def self.report
    puts "item_druid,catalogRecordId,collection_druid,collection_name,invalid_values\n"

    rows(SQL).compact.each { |row| puts row }
  end

  def self.rows(sql)
    ActiveRecord::Base
      .connection
      .execute(sql)
      .to_a
      .group_by { |row| row['external_identifier'] }
      .map do |id, rows|
        invalid_values = invalid_with_encoding(rows)
        next if invalid_values.blank?

        collection_druid = rows.first['collection_id']
        collection_name = Collection.find_by(external_identifier: collection_druid)&.label

        [
          id,
          rows.first['catalogRecordId'],
          collection_druid,
          "\"#{collection_name}\"",
          invalid_values.join(';')
        ].join(',')
      end
  end

  # return all the values for the encoding that fail validation for the encoding
  # the sql_result_rows object is an array of hashes with keys: date, external_identifier, catalogRecordId, ...
  def self.invalid_with_encoding(sql_result_rows)
    invalid_values = []
    # get the value of the dates property, which is json, for each sql result row
    sql_result_rows.filter_map { |row| row['dates'] }.each do |dates_str|
      JSON.parse(dates_str).each do |cocina_date|
        invalid_values << invalid_values(cocina_date) if date_has_encoding?(cocina_date)
      end
    end
    invalid_values.flatten.compact
  end

  def self.date_has_encoding?(cocina_date)
    DATE_ENCODING_JSON_PATH.on(cocina_date).present?
  end

  def self.invalid_values(cocina_date)
    invalid_values = []
    DATE_VALUE_JSON_PATH.on(cocina_date).each do |value|
      invalid_values << value unless valid_w3cdtf?(value)
    end
    invalid_values
  end

  def self.valid_w3cdtf?(date_value)
    Time.w3cdtf(date_value)
  rescue ArgumentError
    # NOTE: the upstream W3CDTF implementation in the `rss` gem does not
    #       allow two patterns that should be valid per the specification:
    #
    # * YYYY
    # * YYYY-MM
    #
    # So we catch the false positives from the upstream gem and allow
    # these two patterns to validate
    /\A\d{4}(-0[1-9]|-1[0-2])?\Z/.match?(date_value)
  end
end
