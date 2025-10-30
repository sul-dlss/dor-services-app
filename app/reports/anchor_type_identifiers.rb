# frozen_string_literal: true

# Report on dros with identifiers of type `anchor`

# Invoke via:
# bin/rails r -e production "AnchorTypeIdentifiers.report"
class AnchorTypeIdentifiers
  # NOTE: Prefer strict JSON querying over lax when using the `.**` operator, per
  #       https://www.postgresql.org/docs/14/functions-json.html#STRICT-AND-LAX-MODES
  JSON_PATH = 'strict $.**.identifier[*] ? (@.type == "anchor")'

  SQL_QUERY = <<~SQL.squish.freeze
    SELECT ro.external_identifier as object_druid,
           jsonb_path_query(rov.structural, '$.isMemberOf') ->> 0 as collection_druid
           FROM repository_objects AS ro, repository_object_versions AS rov
           WHERE ro.head_version_id = rov.id
           AND ro.object_type = 'dro'
           AND jsonb_path_exists(rov.description, '#{JSON_PATH}')
  SQL

  def self.report
    puts 'object_druid,collection_druid'

    ActiveRecord::Base.connection.execute(SQL_QUERY).to_a.each do |row|
      next if row.blank?

      puts [
        row['object_druid'],
        row['collection_druid']
      ].to_csv
    end
  end
end
