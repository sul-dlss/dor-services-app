# frozen_string_literal: true

# Invoke via:
# bin/rails r -e production "EventsMultipleDateTypes.report"
class EventsMultipleDateTypes
  # NOTE: Prefer strict JSON querying over lax when using the `.**` operator, per
  #       https://www.postgresql.org/docs/14/functions-json.html#STRICT-AND-LAX-MODES
  #
  # > The .** accessor can lead to surprising results when using the lax mode.
  # > ... This happens because the .** accessor selects both the segments array
  # > and each of its elements, while the .HR accessor automatically unwraps
  # > arrays when using the lax mode. To avoid surprising results, we recommend
  # > using the .** accessor only in the strict mode.

  # find events in cocina objects
  EVENT_JSONB_PATH = 'strict $.event'
  # find events in cocina objects that have at least one date with a type
  #   note that date.type gets empty results because dates are arrays
  EVENT_WITH_TYPED_DATE_JSONB_PATH = 'strict $.event.**.date.**.type'

  SQL = <<~SQL.squish.freeze
    SELECT jsonb_path_query(rov.description, '#{EVENT_JSONB_PATH}') ->> 0 as event,
           ro.external_identifier,
           jsonb_path_query(rov.identification, '$.catalogLinks[*] ? (@.catalog == "folio").catalogRecordId') ->> 0 as catalogRecordId,
           jsonb_path_query(rov.structural, '$.isMemberOf') ->> 0 as collection_id
           FROM repository_objects AS ro, repository_object_versions AS rov
           WHERE rov.id = ro.head_version_id
           AND jsonb_path_exists(rov.description, '#{EVENT_WITH_TYPED_DATE_JSONB_PATH}')
  SQL

  def self.report
    puts "item_druid,catalogRecordId,collection_druid,collection_name,date_types\n"

    result_rows(SQL).compact.each { |row| puts row }
  end

  def self.result_rows(sql)
    ActiveRecord::Base
      .connection
      .execute(sql)
      .to_a
      .group_by { |row| row['external_identifier'] }
      .map do |id, rows|
        event_date_types = event_date_types(rows)
        next if event_date_types.blank? || event_date_types.size == 1

        collection_druid = rows.first['collection_id']
        collection_name = Collection.find_by(external_identifier: collection_druid)&.label

        [
          id,
          rows.first['catalogRecordId'],
          collection_druid,
          "\"#{collection_name}\"",
          event_date_types.join(';')
        ].join(',')
      end
  end

  # @param sql_result_rows [Array<Hash>] hash has keys: event, external_identifier, catalogRecordId, ...
  # @return [Array<String>] the unique types from each date in an event
  def self.event_date_types(sql_result_rows)
    event_date_types = []
    # get the value of the event property, which is json, for each sql result row
    sql_result_rows.filter_map { |row| row['event'] }.each do |event_json_str|
      cocina_event = JSON.parse(event_json_str)

      event_date_types << unique_date_types(cocina_event)
    end
    event_date_types.flatten.uniq
  end

  # @return [Array<String>] the distinct date types for the event (type as a direct property of date)
  def self.unique_date_types(cocina_event)
    cocina_event['date'].filter_map { |date| date['type'] }.compact.uniq
  end
end
