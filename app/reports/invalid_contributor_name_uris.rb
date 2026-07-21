# frozen_string_literal: true

# Invoke via:
# bin/rails r -e production "InvalidContributorNameUris.report"
#
# Report on objects with values in ..contributor.name.uri that do not begin with
# http(s)://id.loc.gov/authorities/names.
# See https://github.com/sul-dlss/dor-services-app/issues/6006
class InvalidContributorNameUris
  # Scoped to top-level contributor to avoid matching adminMetadata.contributor entries.
  JSON_PATH = '$.contributor[*].name[*] ? (exists(@.uri)).uri'
  REGEX = '"^https?://(?!id\\.loc\\.gov/authorities/names/..).*$"'

  def self.sql
    <<~SQL.squish
      SELECT jsonb_path_query(rov.description, '#{JSON_PATH} ? (@ like_regex #{REGEX})') ->> 0 as value,
             ro.external_identifier,
             jsonb_path_query(rov.description, '$.title[0].structuredValue[*] ? (@.type == "main title").value') ->> 0 as structured_title,
             jsonb_path_query(rov.description, '$.title[0].value') ->> 0 as title,
             jsonb_path_query(rov.identification, '$.catalogLinks[*] ? (@.catalog == "folio").catalogRecordId') ->> 0 as hrid,
             jsonb_path_query(rov.structural, '$.isMemberOf') ->> 0 as collection_id,
             jsonb_path_query(rov.administrative, '$.hasAdminPolicy') ->> 0 as apo
             FROM repository_objects AS ro, repository_object_versions AS rov WHERE
             ro.head_version_id = rov.id
             AND ro.object_type = 'dro'
             AND jsonb_path_exists(rov.description, '#{JSON_PATH} ? (@ like_regex #{REGEX})')
    SQL
  end

  def self.report
    puts "item_druid,value,title,collection_druid,collection_name,hrid,apo_druid,apo_name\n"

    rows(sql).each { |row| puts row }
  end

  def self.rows(query)
    ActiveRecord::Base
      .connection
      .execute(query)
      .to_a
      .group_by { |row| row['external_identifier'] }
      .map do |id, rows|
        collection_druid = rows.first['collection_id']
        collection_head_version = RepositoryObject.collections.find_by(external_identifier: collection_druid)&.head_version
        if collection_head_version&.has_cocina?
          collection_name = Cocina::Models::Builders::TitleBuilder.build(collection_head_version.to_cocina.description.title)
        end
        apo_druid = rows.first['apo']
        apo_name = RepositoryObject.admin_policies.find_by(external_identifier: apo_druid)&.head_version&.label
        title = (rows.first['structured_title'] || rows.first['title'])&.delete("\n")

        [
          id,
          rows.pluck('value').join(';'),
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
