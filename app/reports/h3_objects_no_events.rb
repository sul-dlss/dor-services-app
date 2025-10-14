# frozen_string_literal: true

# Report on H3 objects missing a deposit event.

# Invoke via:
# bin/rails r -e production "H3ObjectsNoEvents.report"
class H3ObjectsNoEvents
  # NOTE: Prefer strict JSON querying over lax when using the `.**` operator, per
  #       https://www.postgresql.org/docs/14/functions-json.html#STRICT-AND-LAX-MODES
  #
  # > The .** accessor can lead to surprising results when using the lax mode.
  # > ... This happens because the .** accessor selects both the segments array
  # > and each of its elements, while the .HR accessor automatically unwraps
  # > arrays when using the lax mode. To avoid surprising results, we recommend
  # > using the .** accessor only in the strict mode.
  JSONB_PATH = 'strict $.**.event[*]'
  SQL = <<~SQL.squish.freeze
    SELECT item_druid, collection_druid
    FROM (
      SELECT ro.external_identifier as item_druid,
             jsonb_path_query(rov.structural, '$.isMemberOf') ->> 0 as collection_druid,
             rov.administrative ->'hasAdminPolicy' ->> 0 AS admin_policy
             FROM repository_objects AS ro,
             repository_object_versions AS rov
             WHERE
             ro.head_version_id = rov.id
             AND ro.object_type = 'dro'
             AND NOT jsonb_path_exists(rov.description, '#{JSONB_PATH}')
    ) Q1
    WHERE admin_policy = 'druid:zw306xn5593'
  SQL

  def self.report
    puts "item_druid,collection_druid\n"
    rows(SQL).compact.each { |row| puts row }
  end

  def self.rows(sql_query)
    sql_result_rows = ActiveRecord::Base.connection.execute(sql_query).to_a

    sql_result_rows.map do |row|
      [
        row['item_druid'],
        row['collection_druid']
      ].to_csv
    end
  end
end
