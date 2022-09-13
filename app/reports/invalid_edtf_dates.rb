# frozen_string_literal: true

# This report is hopefully complete, finding dates with *indicated* edtf encoding
#   - with the encoding as a direct property of date
#   - with structuredValues
#   etc.
#  NOTE:  it does NOT find the structuredValues with value level encoding on only ONE
#   of the values;  invalid_edtf_structured_dates.rb finds those cases.
#  NOTE:  it is believed that this report supersedes bad_edtf_dates.rb
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
  DATE_EDTF_JSON_PATH = 'strict $.**.date ? (@.**.encoding.code == "edtf")'
  SQL = <<~SQL.squish.freeze
    SELECT jsonb_path_query(description, '#{DATE_EDTF_JSON_PATH}') ->> 0 as date,
           external_identifier,
           jsonb_path_query(identification, '$.catalogLinks[*] ? (@.catalog == "symphony").catalogRecordId') ->> 0 as catkey,
           jsonb_path_query(structural, '$.isMemberOf') ->> 0 as collection_id
           FROM "dros" WHERE
           jsonb_path_exists(description, '#{DATE_EDTF_JSON_PATH}')
  SQL

  def self.report
    puts "item_druid,catkey,collection_druid,collection_name,value\n"

    rows(SQL).compact.each { |row| puts row }
  end

  def self.rows(sql)
    ActiveRecord::Base
      .connection
      .execute(sql)
      .to_a
      .group_by { |row| row['external_identifier'] }
      .map do |id, rows|
        bad_values = sql_result_bad_values(rows)
        next if bad_values.blank?

        collection_druid = rows.first['collection_id']
        collection_name = Collection.find_by(external_identifier: collection_druid)&.label

        [
          id,
          rows.first['catkey'],
          collection_druid,
          "\"#{collection_name}\"",
          bad_values.join(';')
        ].join(',')
      end
  end

  # the rows object is an array of hashes with keys: date, external_identifier, catkey, ...
  def self.sql_result_bad_values(rows)
    bad_values = []
    # get the value of the date, which is json, for each row
    # FIXME: to be perfect, this would check if the encoding applies to each date,
    #   but that's a whole separate hell of structuredValues and whether
    #   encoding is at the level of the individual value or for the structuredValue yadda yadda
    rows.map { |row| row['date'] }.each do |date_str|
      bad_values << bad_values(JSON.parse(date_str))
    end
    bad_values.flatten.compact
  end

  DATE_VALUE_JSON_PATH = JsonPath.new('$..value').freeze

  def self.bad_values(date_json)
    bad_values = []
    DATE_VALUE_JSON_PATH.on(date_json).each do |value|
      bad_values << value unless valid_edtf?(value)
    end
    bad_values
  end

  def self.valid_edtf?(date_value)
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
