# frozen_string_literal: true

# This report does NOT find the structuredValues with value level encoding on only ONE
#   of the values;  invalid_edtf_structured_dates.rb finds those cases.
#
# Invoke via:
# bin/rails r -e production "InvalidEdtfDates.report"
class InvalidEdtfDates
  # NOTE: Prefer strict JSON querying over lax when using the `.**` operator, per
  #       https://www.postgresql.org/docs/14/functions-json.html#STRICT-AND-LAX-MODES
  #
  # > The .** accessor can lead to surprising results when using the lax mode.
  # > ... This happens because the .** accessor selects both the segments array
  # > and each of its elements, while the .HR accessor automatically unwraps
  # > arrays when using the lax mode. To avoid surprising results, we recommend
  # > using the .** accessor only in the strict mode.

  # find cocina objects that have at least one date with the encoding
  DATE_JSONB_PATH = 'strict $.**.date ? (@.**.encoding.code == "edtf")'
  # find individual cocina date objects that match the encoding
  DATE_ENCODING_JSON_PATH = JsonPath.new('$..encoding.code[?(@ == "edtf")]').freeze
  # find all the values for a cocina date object (e.g. there may be a structuredValue)
  DATE_VALUE_JSON_PATH = JsonPath.new('$..value').freeze

  SQL = <<~SQL.squish.freeze
    SELECT jsonb_path_query_array(rov.description, '#{DATE_JSONB_PATH}') ->> 0 as dates,
           ro.external_identifier,
           jsonb_path_query(rov.identification, '$.catalogLinks[*] ? (@.catalog == "folio").catalogRecordId') ->> 0 as catalogRecordId,
           jsonb_path_query(rov.structural, '$.isMemberOf') ->> 0 as collection_id
           FROM repository_objects AS ro, repository_object_versions AS rov WHERE
           ro.head_version_id = rov.id
           AND ro.object_type = 'dro'
           AND jsonb_path_exists(rov.description, '#{DATE_JSONB_PATH}')
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
        collection_name = RepositoryObject.collections.find_by(external_identifier: collection_druid)&.head_version&.label

        [
          id,
          rows.first['catalogRecordId'],
          collection_druid,
          collection_name,
          invalid_values.join(';')
        ].to_csv
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
      invalid_values << value unless valid_edtf?(value)
    end
    invalid_values
  end

  def self.valid_edtf?(date_value)
    return false if date_value == 'XXXX' # https://github.com/inukshuk/edtf-ruby/issues/41

    # edtf! raises error if it can't parse it
    Date.edtf!(date_value) ? true : false
  rescue ArgumentError
    # NOTE: the upstream EDTF implementation in the `edtf` gem does not
    #       allow a valid pattern that we use (possibly because only level
    #       0 of the spec was implemented?):
    #
    # * Y-20555
    #
    # So we catch the false positives from the upstream gem and allow
    # this pattern to validate
    /\AY-?\d{5,}\Z/.match?(date_value)
  end
end
