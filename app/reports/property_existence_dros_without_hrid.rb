# frozen_string_literal: true

# Report dro objects with occurrences of a property.
#
# Invoke via: `bin/rails r -e production PropertyExistenceDrosWithoutHrid.report`
class PropertyExistenceDrosWithoutHrid
  # This name is misleading: it can be any valid JSON path desired, not just a
  # single property, e.g. `contributor[*].type`, `groupedValue`,
  # `relatedResource.**.relatedResource`
  PROPERTY = 'groupedValue'

  # JSON_PATH may need to be changed, in addition to PROPERTY, depending on
  # whether or not you're dealing with an array-like property. If the value of
  # PROPERTY is array-like, and you don't care about empties, make sure
  # JSON_PATH ends with `? (@.size() > 0))`

  # NOTE: Prefer strict JSON querying over lax when using the `.**` operator, per
  #       https://www.postgresql.org/docs/14/functions-json.html#STRICT-AND-LAX-MODES
  JSON_PATH = "strict $.**.#{PROPERTY} ? (@.size() > 0)".freeze

  SQL_QUERY = <<~SQL.squish.freeze
    SELECT ro.external_identifier as item_druid,
           jsonb_path_query(rov.description, '$.title[0].value') ->> 0 as title,
           jsonb_path_query(rov.identification, '$.catalogLinks[*] ? (@.catalog == "folio").catalogRecordId') ->> 0 as folio_instance_hrid,
           jsonb_path_query(rov.structural, '$.isMemberOf') ->> 0 as collection_druid
           FROM repository_objects AS ro, repository_object_versions AS rov
           WHERE ro.head_version_id = rov.id
           AND ro.object_type = 'dro'
           AND jsonb_path_exists(rov.description, '#{JSON_PATH}')
           AND NOT jsonb_path_exists(rov.identification, '$.catalogLinks[*] ? (@.catalog == "folio").catalogRecordId')
  SQL

  def self.report
    puts 'item_druid,item_title,collection_druid,folio_instance_hrid'

    ActiveRecord::Base.connection.execute(SQL_QUERY).to_a.each do |row|
      next if row.blank?

      collection_name = RepositoryObject.collections.find_by(external_identifier: row['collection_druid'])&.head_version&.label

      puts [
        row['item_druid'],
        row['title'],
        row['collection_druid'],
        collection_name
      ].to_csv
    end
  end
end
