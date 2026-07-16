# frozen_string_literal: true

# Objects with an identifier.uri where the identifier type is "doi" or source.value is
# "DOI" (case-insensitive) that does not begin with http(s)://doi.org/10.
# See https://github.com/sul-dlss/dor-services-app/issues/6248
# Invoke via:
# bin/rails r -e production "InvalidDoiUris.report"
class InvalidDoiUris
  DOI_URI_REGEX = '^https?://doi\.org/10\.'

  JSON_PATH = 'strict $.**.identifier[*] ? (' \
              '(@.type like_regex "^doi$" flag "i" || @.source.value like_regex "^doi$" flag "i") ' \
              "&& exists(@.uri) && !(@.uri like_regex \"#{DOI_URI_REGEX}\" flag \"i\"))".freeze

  SQL = <<~SQL.squish.freeze
    SELECT jsonb_path_query(rov.description, '#{JSON_PATH}.uri') ->> 0 as value,
           ro.external_identifier,
           jsonb_path_query(rov.description, '$.title[0].structuredValue[*] ? (@.type == "main title").value') ->> 0 as structured_title,
           jsonb_path_query(rov.description, '$.title[0].value') ->> 0 as title,
           jsonb_path_query(rov.identification, '$.catalogLinks[*] ? (@.catalog == "folio").catalogRecordId') ->> 0 as hrid,
           jsonb_path_query(rov.structural, '$.isMemberOf') ->> 0 as collection_id,
           jsonb_path_query(rov.administrative, '$.hasAdminPolicy') ->> 0 as apo
           FROM repository_objects AS ro, repository_object_versions AS rov WHERE
           ro.head_version_id = rov.id
           AND ro.object_type = 'dro'
           AND jsonb_path_exists(rov.description, '#{JSON_PATH}')
  SQL

  def self.report
    puts "item_druid,value,title,collection_druid,collection_name,hrid,apo_druid,apo_name\n"

    rows(SQL).each { |row| puts row }
  end

  def self.rows(query)
    ActiveRecord::Base
      .connection
      .execute(query)
      .to_a
      .group_by { |row| row['external_identifier'] }
      .map do |id, rows|
        collection_druid = rows.first['collection_id']
        collection_name = RepositoryObject.collections.find_by(external_identifier: collection_druid)&.head_version&.label
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
