# frozen_string_literal: true

# Report on H3 objects missing a deposit event.

# Invoke via:
# bin/rails r -e production "H3ObjectsNoDepositEvent.report"
class H3ObjectsNoDepositEvent
  # NOTE: Prefer strict JSON querying over lax when using the `.**` operator, per
  #       https://www.postgresql.org/docs/14/functions-json.html#STRICT-AND-LAX-MODES
  #
  # > The .** accessor can lead to surprising results when using the lax mode.
  # > ... This happens because the .** accessor selects both the segments array
  # > and each of its elements, while the .HR accessor automatically unwraps
  # > arrays when using the lax mode. To avoid surprising results, we recommend
  # > using the .** accessor only in the strict mode.
  JSONB_PATH = 'strict $.**.event[*] ? (@.type == "deposit")'
  SQL = <<~SQL.squish.freeze
    SELECT ro.external_identifier AS item_druid,
           ro.updated_at AS last_updated,
           rov.version AS current_version,
           jsonb_path_query(rov.structural, '$.isMemberOf') ->> 0 as collection_druid
    FROM repository_object_versions AS rov, ((repository_objects AS ro
    JOIN administrative_tags ON administrative_tags.druid = ro.external_identifier)
    JOIN tag_labels ON tag_labels.id = administrative_tags.tag_label_id)
    WHERE ro.head_version_id = rov.id
    AND ro.object_type = 'dro'
    AND tag_labels.tag LIKE 'Project : H3%'
    AND NOT jsonb_path_exists(rov.description, '#{JSONB_PATH}')
  SQL

  def self.report
    puts 'item_druid,version,updated_at,collection_druid'

    ActiveRecord::Base.connection.execute(SQL).to_a
                      .sort_by { |row| row['last_updated'] }
                      .each do |row|
                        puts [
                          row['item_druid'],
                          row['current_version'],
                          row['last_updated'],
                          row['collection_druid']
                        ].to_csv
    end
  end
end
