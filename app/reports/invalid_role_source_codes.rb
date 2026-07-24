# frozen_string_literal: true

# Invoke via:
# bin/rails r -e production "InvalidRoleSourceCodes.report"
class InvalidRoleSourceCodes
  # NOTE: Prefer strict JSON querying over lax when using the `.**` operator, per
  #       https://www.postgresql.org/docs/14/functions-json.html#STRICT-AND-LAX-MODES
  #
  # > The .** accessor can lead to surprising results when using the lax mode.
  # > ... This happens because the .** accessor selects both the segments array
  # > and each of its elements, while the .HR accessor automatically unwraps
  # > arrays when using the lax mode. To avoid surprising results, we recommend
  # > using the .** accessor only in the strict mode.
  JSON_PATH = 'strict $.**.contributor[*].role[*].source.code'
  VALID_CODES = %w[marcrelator rbmsrel].freeze
  REGEX = "^(?!#{VALID_CODES.map { |code| "#{code}$" }.join('|')})".freeze
  SQL = <<~SQL.squish.freeze
    SELECT jsonb_path_query(rov.description, '#{JSON_PATH} ? (@ like_regex "#{REGEX}")') ->> 0 as value,
           ro.external_identifier,
           jsonb_path_query(rov.description, '$.title[0].structuredValue[*] ? (@.type == "main title").value') ->> 0 as structured_title,
           jsonb_path_query(rov.description, '$.title[0].value') ->> 0 as title,
           jsonb_path_query(rov.identification, '$.catalogLinks[*] ? (@.catalog == "folio").catalogRecordId') ->> 0 as hrid,
           jsonb_path_query(rov.structural, '$.isMemberOf') ->> 0 as collection_id,
           jsonb_path_query(rov.administrative, '$.hasAdminPolicy') ->> 0 as apo
           FROM repository_objects AS ro, repository_object_versions AS rov WHERE
           ro.head_version_id = rov.id
           AND ro.object_type = 'dro'
           AND jsonb_path_exists(rov.description, '#{JSON_PATH} ? (@ like_regex "#{REGEX}")')
  SQL

  def self.report
    puts "item_druid,value,title,collection_druid,collection_name,hrid,apo_druid,apo_name\n"

    rows(SQL).each { |row| puts row }
  end

  def self.rows(sql)
    ActiveRecord::Base
      .connection
      .execute(sql)
      .to_a
      .group_by { |row| row['external_identifier'] }
      .map do |id, rows|
      collection_druid = rows.first['collection_id']
      collection_head_version = RepositoryObject.collections.find_by(external_identifier: collection_druid)&.head_version
      if collection_head_version&.has_cocina?
        collection_name = Cocina::Models::Builders::TitleBuilder.build(collection_head_version.to_cocina.description.title)
      end
      apo_druid = rows.first['apo']
      apo_head_version = RepositoryObject.admin_policies.find_by(external_identifier: apo_druid)&.head_version
      if apo_head_version&.has_cocina?
        apo_description = apo_head_version.to_cocina.description
        apo_name = Cocina::Models::Builders::TitleBuilder.build(apo_description.title) if apo_description
      end
      title = (rows.first['structured_title'] || rows.first['title'])&.delete("\n")

      [
        id,
        rows.pluck('value').uniq.join(';'),
        title,
        collection_druid,
        collection_name,
        rows.first['hrid'],
        apo_druid,
        apo_name
      ].to_csv
    end
  end
end
