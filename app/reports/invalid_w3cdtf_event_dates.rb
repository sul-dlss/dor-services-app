# frozen_string_literal: true

# Report on instances where the date value in an event does not match 'w3cdtf'
# encoding. The encoding may be a sibling to date.value or date.structuredValue
# (i.e., if the date is structured, the encoding may be at the level of the
# structuredValue rather than the value).
#
# Events can occur at the top level of description, in relatedResource, or adminMetadata.
#
# See: https://www.w3.org/TR/NOTE-datetime
# See: https://github.com/sul-dlss/dor-services-app/issues/6134
#
# Invoke via:
# bin/rails r -e production "InvalidW3cdtfEventDates.report"
class InvalidW3cdtfEventDates
  # NOTE: Prefer strict JSON querying over lax when using the `.**` operator, per
  #       https://www.postgresql.org/docs/14/functions-json.html#STRICT-AND-LAX-MODES
  #
  # > The .** accessor can lead to surprising results when using the lax mode.
  # > ... This happens because the .** accessor selects both the segments array
  # > and each of its elements, while the .HR accessor automatically unwraps
  # > arrays when using the lax mode. To avoid surprising results, we recommend
  # > using the .** accessor only in the strict mode.

  # find cocina objects that have at least one event date with w3cdtf encoding;
  # events can occur at the top level, in relatedResource, or adminMetadata
  DATE_JSONB_PATH = 'strict $.**.event.**.date ? (@.**.encoding.code == "w3cdtf")'
  # find individual cocina date objects that have w3cdtf encoding
  DATE_ENCODING_JSON_PATH = Janeway.parse('$..encoding.code')
  # find all the values for a cocina date object (e.g. there may be a structuredValue)
  DATE_VALUE_JSON_PATH = Janeway.parse("$..['value']")

  SQL = <<~SQL.squish.freeze
    SELECT jsonb_path_query_array(rov.description, '#{DATE_JSONB_PATH}') ->> 0 as dates,
           ro.external_identifier,
           jsonb_path_query(rov.identification, '$.catalogLinks[*] ? (@.catalog == "folio").catalogRecordId') ->> 0 as catalogRecordId,
           jsonb_path_query(rov.structural, '$.isMemberOf') ->> 0 as collection_id
           FROM repository_objects AS ro, repository_object_versions AS rov
           WHERE ro.head_version_id = rov.id
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

  # return all the values for the encoding that fail w3cdtf validation
  # the sql_result_rows object is an array of hashes with keys: dates, external_identifier, catalogRecordId, ...
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

  # NOTE: this check is still needed even though the SQL query filters on w3cdtf encoding.
  # The JSONPath filter operates at the `date` array level: it selects the entire array if
  # *any* element within it has w3cdtf encoding. That means a mixed-encoding date array
  # (e.g. one date with w3cdtf, another with edtf) will be returned in full, and we must
  # skip individual date objects that aren't actually claiming w3cdtf before validating.
  def self.date_has_encoding?(cocina_date)
    DATE_ENCODING_JSON_PATH.enum_for(cocina_date).search.include?('w3cdtf')
  end

  def self.invalid_values(cocina_date)
    invalid_values = []
    DATE_VALUE_JSON_PATH.enum_for(cocina_date).search.each do |value|
      invalid_values << value unless valid_w3cdtf?(value)
    end
    invalid_values
  end

  def self.valid_w3cdtf?(date_value)
    Cocina::Models::Validators::W3cdtfValidator.validate(date_value)
  end
end
