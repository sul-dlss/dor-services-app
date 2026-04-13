# frozen_string_literal: true

# Invoke via:
# bin/rails r -e production "InvalidRoleCodes.report"
class InvalidRoleCodes
  # NOTE: Prefer strict JSON querying over lax when using the `.**` operator, per
  #       https://www.postgresql.org/docs/14/functions-json.html#STRICT-AND-LAX-MODES
  #
  # > The .** accessor can lead to surprising results when using the lax mode.
  # > ... This happens because the .** accessor selects both the segments array
  # > and each of its elements, while the .HR accessor automatically unwraps
  # > arrays when using the lax mode. To avoid surprising results, we recommend
  # > using the .** accessor only in the strict mode.
  JSON_PATH = 'strict $.**.contributor[*].role[*].code'
  MARC_RELATORS_URL = 'https://raw.githubusercontent.com/sul-dlss/cocina_display/main/config/marc_relators.yml'

  def self.valid_codes
    response = Faraday.get(MARC_RELATORS_URL)
    YAML.safe_load(response.body).keys
  end

  def self.regex
    codes = valid_codes
    "^(?!#{codes.map { |code| "#{code}$" }.join('|')})"
  end

  def self.sql
    r = regex
    <<~SQL.squish
      SELECT jsonb_path_query(rov.description, '#{JSON_PATH} ? (@ like_regex "#{r}")') ->> 0 as value,
             ro.external_identifier,
             jsonb_path_query(rov.description, '$.title[0].structuredValue[*] ? (@.type == "main title").value') ->> 0 as structured_title,
             jsonb_path_query(rov.description, '$.title[0].value') ->> 0 as title,
             jsonb_path_query(rov.identification, '$.catalogLinks[*] ? (@.catalog == "folio").catalogRecordId') ->> 0 as hrid,
             jsonb_path_query(rov.structural, '$.isMemberOf') ->> 0 as collection_id,
             jsonb_path_query(rov.administrative, '$.hasAdminPolicy') ->> 0 as apo
             FROM repository_objects AS ro, repository_object_versions AS rov WHERE
             ro.head_version_id = rov.id
             AND ro.object_type = 'dro'
             AND jsonb_path_exists(rov.description, '#{JSON_PATH} ? (@ like_regex "#{r}")')
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
